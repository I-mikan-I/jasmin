(* * Typing of IL *)

(* ** Imports *)
open IL_Lang
open IL_Utils
open Util
open Arith
open Core_kernel.Std

module P = ParserUtil
module L = ParserUtil.Lexing

(* ** Check type information and propagate to pregs
 * ------------------------------------------------------------------------ *)

(* *** Typing environment
 * ------------------------------------------------------------------------ *)

type penv = ty   String.Map.t
type fenv = func String.Map.t
type tenv = ty   String.Map.t

type env = {
  e_penv : penv;
  e_fenv : fenv;
  e_tenv : tenv;
}

let tenv_of_func func decls =
  String.Map.of_alist_exn (List.map ~f:(fun (_,m,t) -> (m,t)) (func.f_args@decls))

let type_error_ d fmt =
  let buf  = Buffer.create 127 in
  let fbuf = F.formatter_of_buffer buf in
  F.kfprintf
    (fun _ ->
      F.pp_print_flush fbuf ();
      let s = Buffer.contents buf in
      failtype d.d_loc s)
    fbuf fmt

let type_error d s = failtype d.d_loc s

(* *** Compute types of registers taking (array) indexes into account
 * ------------------------------------------------------------------------ *)

let equiv_ty ty1 ty2 =
  match ty1, ty2 with
  | Bool,    Bool    -> true
  | U64    , U64     -> true
  | Arr(d1), Arr(d2) -> equal_dexpr d1 d2
  | _,       _       -> false

let get_dim (dim : pexpr) (lb_o,ub_o) =
  let zero = Pconst U64.zero in
  let lb = get_opt zero lb_o in
  let ub = get_opt dim ub_o in
  if equal_pexpr lb zero
  then ub
  else Pbinop(Pminus,ub,lb)

(** [type_dest_app pr ty] takes a pseudo-register pr<ies> and the
    type of pr and returns the type of pr<ies>.
    Example: for pr<3,0..n> with pr : u64<5,n>[n], the result is u64<n>[n] *)
let type_dest_app d ty =
  match ty with
  | Bool | U64 ->
    if Option.is_some d.d_oidx then
      type_error_ d "register has type %a, cannot access array element" pp_ty ty;
    ty
  | Arr(_dim) as ty ->
    begin match d.d_oidx with
    | None    -> ty
    | Some(_) -> U64
    end

(** Same as [type_dest_app] except that it looks up the type from [tenv] *)
let type_dest (tenv : tenv) d =
  type_dest_app d (map_find_exn ~err:(type_error d) tenv pp_string d.d_name)

(** Same as [type_dest] except that it asserts that type is equal to [ty_exp] *)
let typecheck_dest (tenv : tenv) d ty_exp =
  let ty = type_dest tenv d in
  if not (equiv_ty ty ty_exp) then
    type_error_ d "type mismatch (got %a, expected %a)" pp_ty ty pp_ty ty_exp

(** Takes source and computes its type (see [type_dest]) *)
let type_src (env : env) = function
  | Imm(_) -> U64
  | Src(d) -> type_dest env.e_tenv d

(** Same as [type_dest] except that it asserts that type is equal to [ty_exp] *)
let typecheck_src (env : env) s ty_exp =
  match s with
  | Imm(_) -> if not (equal_ty ty_exp (U64)) then assert false
  | Src(d) -> typecheck_dest env.e_tenv d ty_exp

(* *** Check types for assignments, destinations, and sources
 * ------------------------------------------------------------------------ *)

(** Ensures that the source and destination for assignments are compatible *)
let typecheck_assgn (env : env) d s pos =
  let ty_s = type_src  env s in
  let ty_d = type_dest env.e_tenv d in
  if not (equiv_ty ty_s ty_d) then (
    failtype_ pos "incompatible types for assignment: lhs %, rhs %a)"
      pp_ty ty_d pp_ty ty_s
  ) (* FIXME: disallow flag assignments here? *)

(*
(** Checks that the base type of the given destination [t] is equal to [t] *)
let type_dest_eq (env : env) d ty_exp =
  let ty = map_find_exn ~err:(type_error d) env.e_tenv pp_string d.d_name in
  if not (equiv_ty ty ty_exp) then (
    type_error_ d "incompatible types, expected %a, got %a)"
      pp_ty ty_exp pp_ty ty
  )
*)

(** Checks that the base type of the given source is equal to [t] *)
let type_src_eq (env : env) src ty_exp =
  match src, ty_exp with
  | Imm _,  Bool   -> failwith "got u64, expected bool"
  | Imm _,  U64    -> ()
  | Imm _,  Arr(_) -> failwith "got u64, expected u64[..]"
  | Src(d), t      -> typecheck_dest env.e_tenv d t

(* *** Check types for ops, instructions, statements, and functions
 * ------------------------------------------------------------------------ *)

(** typecheck operators *)
let typecheck_op (env : env) op z x y =
  let type_src_eq  = type_src_eq  env in
  let type_dest_eq = typecheck_dest env.e_tenv in
  match op with

  | Umul(h) ->
    type_src_eq  x U64;
    type_src_eq  y U64;
    type_dest_eq z U64;
    type_dest_eq h U64

  | Carry(_,mcf_out,mcf_in) ->
    type_src_eq  x U64;
    type_src_eq  y U64;
    type_dest_eq z U64;
    Option.iter ~f:(fun s -> type_src_eq  s Bool) mcf_in;
    Option.iter ~f:(fun d -> type_dest_eq d Bool) mcf_out

  | CMov(_,cf_in) ->
    type_src_eq  x     U64;
    type_src_eq  y     U64;
    type_src_eq  cf_in Bool;
    type_dest_eq z     U64

  | ThreeOp(_) ->
    type_src_eq  x U64;
    type_src_eq  y U64;
    type_dest_eq z U64

  | Shift(_dir,mcf_out) ->
    type_src_eq  x U64;
    type_src_eq  y U64;
    type_dest_eq z U64;
    Option.iter ~f:(fun s -> type_dest_eq s Bool) mcf_out

(** typecheck instructions and statements *)
let rec typecheck_instr (env : env) linstr =
  let tc_stmt  = typecheck_stmt  env in
  let tc_op    = typecheck_op    env in
  let tc_assgn = typecheck_assgn env in
  let loc = linstr.L.l_loc in
  match linstr.L.l_val with
  | Binstr(Comment _)             -> ()
  | Binstr(Op(op,d,(s1,s2)))      -> tc_op op d s1 s2
  | Binstr(Assgn(d,s,_))          -> tc_assgn d s loc
  | If(_,stmt1,stmt2)             -> tc_stmt stmt1; tc_stmt stmt2
  | Binstr(Load(d,s,_pe))         -> type_src_eq  env s U64; typecheck_dest env.e_tenv d U64
  | Binstr(Store(s1,_pe,s2))      -> type_src_eq env s1 U64; type_src_eq env s2 U64
  | Binstr(Call(fname,rets,args)) ->
    let cfun = map_find_exn env.e_fenv pp_string fname in
    let tc_src s (_,_,ty_expected) = typecheck_src env s ty_expected in
    let tc_dest d (_,ty_expected) = typecheck_dest env.e_tenv d ty_expected in
    list_iter2_exn args cfun.f_args ~f:tc_src
      ~err:(fun n_g n_e ->
              failtype_ loc "wrong number of arguments (got %i, exp. %i)" n_g n_e);
    list_iter2_exn rets cfun.f_ret_ty ~f:tc_dest
      ~err:(fun n_g n_e ->
              failtype_ loc "wrong number of l-values (got %i, exp. %i)" n_g n_e)
  | For(_,pv,_,_,stmt) ->
    typecheck_dest env.e_tenv { d_loc = loc; d_name = pv; d_oidx = None} U64;
    typecheck_stmt env stmt

and typecheck_stmt (env : env) stmt =
  List.iter ~f:(typecheck_instr env) stmt

(** typecheck return value *)
let typecheck_ret (env : env) ret_ty ret =
  List.iter2_exn ret ret_ty
    ~f:(fun name ty -> typecheck_dest env.e_tenv (mk_dest_name name) ty)

(** typecheck the given function *)
let typecheck_func (penv : penv) (fenv : fenv) func =
  match func.f_def with
  | Undef | Py _ -> ()
  | Def fdef ->
    let tenv = String.Map.of_alist_exn
                 (  (Map.to_alist (tenv_of_func func fdef.fd_decls))
                  @ (Map.to_alist penv))
    in
    let env  = { e_penv = penv; e_fenv = fenv; e_tenv = tenv } in
    typecheck_stmt env fdef.fd_body;
    typecheck_ret env (List.map ~f:snd func.f_ret_ty) fdef.fd_ret

(** typecheck all functions in module *)
let typecheck_modul modul =
  let funcs = modul.m_funcs in
  let fenv = String.Map.of_alist_exn (List.map funcs ~f:(fun f -> (f.f_name, f))) in
  let penv = String.Map.of_alist_exn modul.m_params in
  let params_decl = params_modul modul in
  Set.iter params_decl
    ~f:(fun pv -> if not (Map.mem penv pv) then
                    failtype_ L.dummy_loc "parameter %s not declared (env: %a)"
                      pv (pp_list "," pp_string) (List.map ~f:fst modul.m_params));
  List.iter funcs ~f:(typecheck_func penv fenv)

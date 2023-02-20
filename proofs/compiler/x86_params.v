From mathcomp Require Import all_ssreflect all_algebra.
From mathcomp.word Require Import ssrZ.

Require Import
  arch_params
  compiler_util
  expr.
Require Import
  clear_stack
  linearization
  lowering
  stack_alloc.
Require Import
  arch_decl
  arch_extra
  asm_gen
  label.
Require Import
  x86_decl
  x86_extra
  x86_instr_decl
  x86_lowering.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.


(* ------------------------------------------------------------------------ *)
(* Stack alloc parameters. *)

Definition lea_ptr x y tag ofs : instr_r :=
  Copn [:: x] tag (Ox86 (LEA Uptr)) [:: add y (cast_const ofs)].

Section IS_REGX.

Context (is_regx : var -> bool).

Variant mov_kind :=
  | MK_LEA
  | MK_MOV.

Definition mk_mov vpk :=
  match vpk with
  | VKglob _ | VKptr (Pdirect _ _ _ _ Sglob) => MK_LEA
  | _ => MK_MOV
  end.

Definition x86_mov_ofs x tag vpk y ofs :=
  let addr :=
    if mk_mov vpk is MK_LEA
    then
      lea_ptr x y tag ofs
    else
      if ofs == 0%Z
      then mov_ws is_regx Uptr x y tag
      else lea_ptr x y tag ofs
  in
  Some addr.

End IS_REGX.

Definition x86_saparams is_regx : stack_alloc_params :=
  {|
    sap_mov_ofs := x86_mov_ofs is_regx;
  |}.

(* ------------------------------------------------------------------------ *)
(* Linearization parameters. *)

Definition x86_allocate_stack_frame (rspi: var_i) (sz: Z) :=
  let rspg := Gvar rspi Slocal in
  let p := Papp2 (Osub (Op_w Uptr)) (Pvar rspg) (cast_const sz) in
  ([:: Lvar rspi ], Ox86 (LEA Uptr), [:: p ]).

Definition x86_free_stack_frame (rspi: var_i) (sz: Z) :=
  let rspg := Gvar rspi Slocal in
  let p := Papp2 (Oadd (Op_w Uptr)) (Pvar rspg) (cast_const sz) in
  ([:: Lvar rspi ], Ox86 (LEA Uptr), [:: p ]).

Definition x86_ensure_rsp_alignment (rspi: var_i) (al: wsize) :=
  let to_lvar x := Lvar (VarI (to_var x) dummy_var_info) in
  let eflags := List.map to_lvar [:: OF ; CF ; SF ; PF ; ZF ] in
  let p0 := Pvar (Gvar rspi Slocal) in
  let p1 := cast_const (- wsize_size al) in
  (eflags ++ [:: Lvar rspi ], Ox86 (AND Uptr), [:: p0; p1 ]).

Definition x86_lassign (x: lval) (ws: wsize) (e: pexpr) :=
  let op := if (ws <= U64)%CMP
            then MOV ws
            else VMOVDQU ws
  in Some ([:: x ], Ox86 op, [:: e ]).

Definition x86_liparams : linearization_params :=
  {|
    lip_tmp := "RAX"%string;
    lip_allocate_stack_frame := x86_allocate_stack_frame;
    lip_free_stack_frame := x86_free_stack_frame;
    lip_ensure_rsp_alignment := x86_ensure_rsp_alignment;
    lip_lassign := x86_lassign;
  |}.

(* ------------------------------------------------------------------------ *)
(* Lowering parameters. *)

Definition x86_loparams : lowering_params fresh_vars lowering_options :=
  {|
    lop_lower_i := lower_i;
    lop_fvars_correct := fvars_correct;
  |}.


(* ------------------------------------------------------------------------ *)
(* Assembly generation parameters. *)

Definition not_condt (c : condt) :=
  match c with
  | O_ct => NO_ct
  | NO_ct => O_ct
  | B_ct => NB_ct
  | NB_ct => B_ct
  | E_ct => NE_ct
  | NE_ct => E_ct
  | BE_ct => NBE_ct
  | NBE_ct => BE_ct
  | S_ct => NS_ct
  | NS_ct => S_ct
  | P_ct => NP_ct
  | NP_ct => P_ct
  | L_ct => NL_ct
  | NL_ct => L_ct
  | LE_ct => NLE_ct
  | NLE_ct => LE_ct
  end.

Definition or_condt ii e c1 c2 : cexec condt :=
  match c1, c2 with
  | L_ct, E_ct => ok LE_ct
  | E_ct, L_ct => ok LE_ct
  | B_ct, E_ct => ok BE_ct
  | E_ct, B_ct => ok BE_ct
  | _, _ => Error (E.berror ii e "Invalid condition (OR)")
  end.

Definition and_condt ii e c1 c2 :=
  match c1, c2 with
  | NB_ct, NE_ct => ok NBE_ct
  | NE_ct, NB_ct => ok NBE_ct
  | NE_ct, NL_ct => ok NLE_ct
  | NL_ct, NE_ct => ok NLE_ct
  | _, _ => Error (E.berror ii e "Invalid condition (AND)")
  end.

Definition of_var_e_bool ii (v: var_i) : cexec rflag :=
  match of_var v with
  | Some r => ok r
  | None => Error (asm_gen.E.invalid_flag ii v)
  end.

Fixpoint assemble_cond_r ii (e : pexpr) : cexec condt :=
  match e with
  | Pvar v =>
      Let r := of_var_e_bool ii (gv v) in
      match r with
      | OF => ok O_ct
      | CF => ok B_ct
      | ZF => ok E_ct
      | SF => ok S_ct
      | PF => ok P_ct
      | DF => Error (E.berror ii e "Cannot branch on DF")
      end

  | Papp1 Onot e =>
      Let c := assemble_cond_r ii e in
      ok (not_condt c)

  | Papp2 Oor e1 e2 =>
      Let c1 := assemble_cond_r ii e1 in
      Let c2 := assemble_cond_r ii e2 in
      or_condt ii e c1 c2

  | Papp2 Oand e1 e2 =>
      Let c1 := assemble_cond_r ii e1 in
      Let c2 := assemble_cond_r ii e2 in
      and_condt ii e c1 c2

  | Papp2 Obeq (Pvar x1) (Pvar x2) =>
      Let r1 := of_var_e_bool ii (gv x1) in
      Let r2 := of_var_e_bool ii (gv x2) in
      if ((r1 == SF) && (r2 == OF)) || ((r1 == OF) && (r2 == SF))
      then ok NL_ct
      else Error (E.berror ii e "Invalid condition (NL)")

  | _ => Error (E.berror ii e "don't known how to compile the condition")

  end.

Definition assemble_cond ii (e: pexpr) : cexec condt :=
  assemble_cond_r ii e.

Definition x86_agparams : asm_gen_params :=
  {|
    agp_assemble_cond := assemble_cond;
  |}.


(* ------------------------------------------------------------------------ *)
(* Stack clearing parameters. *)

Section CLEAR_STACK.

Section RSP.

Context (rspi : var_i).

Let vlocal {t T} {_ : ToString t T} (x : T) : gvar :=
  {|
    gv := {| v_info := dummy_var_info; v_var := to_var x; |};
    gs := Slocal;
  |}.

Let tmp : gvar := vlocal RSI.
Let off : gvar := vlocal RDI.
Let r   : gvar := vlocal RCX.
Let vlr : gvar := vlocal XMM2.

Let rsp : gvar := mk_lvar rspi.
Let zf : gvar := vlocal ZF.
Let tmpi : var_i := gv tmp.
Let offi : var_i := gv off.
Let ri   : var_i := gv r.
Let vlri : var_i := gv vlr.
Let zfi : var_i := gv zf.

Let flags_lv :=
  map
    (fun f => Lvar {| v_info := dummy_var_info; v_var := to_var f; |})
    [:: OF; CF; SF; PF; ZF ].

Definition x86_clear_stack_loop_small (lbl : label) ws_align ws (max_stk_size : Z) : lcmd :=
  (* tmp = rsp; *)
  let i0 := Lopn [:: Lvar tmpi ] (Ox86 (MOV U64)) [:: Pvar rsp ] in

  (* tmp &= - (wsize_size ws_align); *)
  let i1 :=
    Lopn
      (flags_lv ++ [:: Lvar tmpi ])
      (Ox86 (AND U64))
      [:: Pvar tmp; pword_of_int U64 (- wsize_size ws_align)%Z ]
  in

  (* off = -max_stk_size; *)
  let i2 :=
    Lopn
      [:: Lvar offi ]
      (Ox86 (MOV U64))
      [:: pword_of_int U64 (- max_stk_size)%Z ]
  in

  (* l1: *)
  let i3 := Llabel InternalLabel lbl in

  (* (ws)[tmp + off] = 0; *)
  let i4 :=
    Lopn [:: Lmem ws tmpi (Pvar off) ] (Ox86 (MOV ws)) [:: pword_of_int ws 0 ]
  in

  (* ?{zf}, off = #ADD(off, wsize_size ws); *)
  let i5 :=
    Lopn
      (flags_lv ++ [:: Lvar offi ])
      (Ox86 (ADD U64))
      [:: Pvar off; pword_of_int U64 (wsize_size ws) ]
  in

  (* if (!zf) goto l1 *)
  let i6 := Lcond (Papp1 Onot (Pvar zf)) lbl in

  map (MkLI dummy_instr_info) [:: i0; i1; i2; i3; i4; i5; i6 ].

Definition i1 := Lopn [:: Lvar tmpi ] (Ox86 (MOV U64)) [:: Pvar rsp ].

(* we read rsp first, so that we are sure that we don't modify it ; otherwise,
   we would have to add hypotheses like rsp <> XMM2 *)
Definition x86_clear_stack_loop_large (lbl : label) ws_align ws (max_stk_size : Z) : lcmd :=
  (* tmp = rsp; *)
  let i1 := Lopn [:: Lvar tmpi ] (Ox86 (MOV U64)) [:: Pvar rsp ] in

  (* ymm = #set0_ws(); *)
  let i0 := Lopn [:: Lvar vlri ] (Oasm (ExtOp (Oset0 ws))) [::] in

  (* tmp &= - (wsize_size ws_align); *)
  let i2 :=
    Lopn
      (flags_lv ++ [:: Lvar tmpi ])
      (Ox86 (AND U64))
      [:: Pvar tmp; pword_of_int U64 (- wsize_size ws_align)%Z ]
  in

  (* off = -max_stk_size; *)
  let i3 :=
    Lopn
      [:: Lvar offi ]
      (Ox86 (MOV U64))
      [:: pword_of_int U64 (- max_stk_size)%Z ]
  in

  (* l1: *)
  let i4 := Llabel InternalLabel lbl in

  (* (ws)[tmp + off] = ymm; *)
  let i5 :=
    Lopn [:: Lmem ws tmpi (Pvar off) ] (Ox86 (VMOVDQU ws)) [:: Pvar vlr ]
  in

  (* ?{zf}, off = #ADD(off, wsize_size ws); *)
  let i6 :=
    Lopn
      (flags_lv ++ [:: Lvar offi ])
      (Ox86 (ADD U64))
      [:: Pvar off; pword_of_int U64 (wsize_size ws) ]
  in

  (* if (!zf) goto l1 *)
  let i7 := Lcond (Papp1 Onot (Pvar zf)) lbl in

  map (MkLI dummy_instr_info) [:: i1; i0; i2; i3; i4; i5; i6; i7 ].

Definition x86_clear_stack_loop lbl ws_align ws max_stk_size :=
  if (ws <= U64)%CMP then x86_clear_stack_loop_small lbl ws_align ws max_stk_size
  else x86_clear_stack_loop_large lbl ws_align ws max_stk_size.

Definition x86_clear_stack_unrolled_small ws_align ws (max_stk_size : Z) : lcmd :=
  (* tmp = rsp; *)
  let i0 := Lopn [:: Lvar tmpi ] (Ox86 (MOV U64)) [:: Pvar rsp ] in

  (* tmp &= - (wsize_size ws_align); *)
  let i1 :=
    Lopn
      (flags_lv ++ [:: Lvar tmpi ])
      (Ox86 (AND U64))
      [:: Pvar tmp; pword_of_int U64 (- wsize_size ws_align)%Z ]
  in

  (* (ws)[tmp + off] = 0; *)
  let f off :=
    Lopn
      [:: Lmem ws tmpi (pword_of_int U64 (- off)) ]
      (Ox86 (MOV ws))
      [:: pword_of_int ws 0 ]
  in

  let offs := map (fun x => x * wsize_size ws)%Z (ziota 1 ((max_stk_size-1) / wsize_size ws + 1)) in

  map (MkLI dummy_instr_info) [:: i0, i1 & map f offs].

Definition x86_clear_stack_unrolled_large ws_align ws (max_stk_size : Z) : lcmd :=
  (* tmp = rsp; *)
  let i1 := Lopn [:: Lvar tmpi ] (Ox86 (MOV U64)) [:: Pvar rsp ] in

  (* ymm = #set0_ws(); *)
  let i0 := Lopn [:: Lvar vlri ] (Oasm (ExtOp (Oset0 ws))) [::] in

  (* tmp &= - (wsize_size ws_align); *)
  let i2 :=
    Lopn
      (flags_lv ++ [:: Lvar tmpi ])
      (Ox86 (AND U64))
      [:: Pvar tmp; pword_of_int U64 (- wsize_size ws_align)%Z ]
  in

  (* (ws)[tmp + off] = ymm; *)
  let f off :=
    Lopn
      [:: Lmem ws tmpi (pword_of_int U64 (- off)) ]
      (Ox86 (VMOVDQU ws))
      [:: Pvar vlr ]
  in

  let offs := map (fun x => x * wsize_size ws)%Z (ziota 1 ((max_stk_size-1) / wsize_size ws + 1)) in

  map (MkLI dummy_instr_info) [:: i1, i0, i2 & map f offs].

End RSP.

Definition x86_clear_stack_unrolled rsp ws_align ws max_stk_size :=
  if (ws <= U64)%CMP then x86_clear_stack_unrolled_small rsp ws_align ws max_stk_size
  else x86_clear_stack_unrolled_large rsp ws_align ws max_stk_size.

Definition x86_clear_stack_cmd
  (css : cs_strategy) rsp (lbl : label) ws_align ws (max_stk_size : Z) : cexec lcmd :=
  match css with
  | CSSloop => ok (x86_clear_stack_loop rsp lbl ws_align ws max_stk_size)
  | CSSunrolled => ok (x86_clear_stack_unrolled rsp ws_align ws max_stk_size)
  end.

End CLEAR_STACK.

Definition x86_csparams : clear_stack_params :=
  {|
    cs_clear_stack_cmd := x86_clear_stack_cmd;
  |}.


(* ------------------------------------------------------------------------ *)
(* Shared parameters. *)

Definition x86_is_move_op (o : asm_op_t) :=
  match o with
  | BaseOp (None, MOV _) => true
  | BaseOp (None, VMOVDQU _) => true
  | _ => false
  end.

(* ------------------------------------------------------------------------ *)

Definition x86_params : architecture_params fresh_vars lowering_options :=
  {|
    ap_sap := x86_saparams;
    ap_lip := x86_liparams;
    ap_lop := x86_loparams;
    ap_agp := x86_agparams;
    ap_csp := x86_csparams;
    ap_is_move_op := x86_is_move_op;
  |}.

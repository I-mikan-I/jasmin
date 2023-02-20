From mathcomp Require Import all_ssreflect all_algebra.
From mathcomp.word Require Import ssrZ.

Require Import
  arch_params_proof
  compiler_util
  expr
  psem
  psem_facts
  one_varmap
  sem_one_varmap.
Require Import
  linearization
  linearization_proof
  lowering
  propagate_inline_proof
  stack_alloc
  stack_alloc_proof
  clear_stack
  clear_stack_proof.
Require
  arch_sem.
Require Import
  arch_decl
  arch_extra
  asm_gen
  asm_gen_proof.
Require Import
  x86_decl
  x86_extra
  x86_instr_decl
  x86_lowering
  x86_lowering_proof.
Require Export x86_params.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope vmap_scope.


Section Section.
Context {syscall_state : Type} {sc_sem : syscall_sem syscall_state}.

Section bla.
Context { ovmi : one_varmap_info }.

(* FIXME: how to reason on all call conv at once ??????? *)
(* Local Existing Instance x86_linux_call_conv. *)

Section CLEAR_STACK.

Context (rspi : var_i).

Let vlocal {t T} {_ : ToString t T} (x : T) : gvar :=
  {|
    gv := {| v_info := dummy_var_info; v_var := to_var x; |};
    gs := Slocal;
  |}.

Let tmp : gvar := vlocal RSI.
Let off : gvar := vlocal RDI.
Let vlr : gvar := vlocal XMM2.

Let rsp : gvar := mk_lvar rspi.
Let zf : gvar := vlocal ZF.
Let tmpi : var_i := gv tmp.
Let offi : var_i := gv off.
Let vlri : var_i := gv vlr.
Let zfi : var_i := gv zf.

Let flags_lv :=
  map
    (fun f => Lvar {| v_info := dummy_var_info; v_var := to_var f; |})
    [:: OF; CF; SF; PF; ZF ].

(*
Definition init_code_unrolled : lcmd :=
  (* ymm = #set0_256(); *)
  let i0 := Lopn [:: Lvar vlri ] (Oasm (ExtOp (Oset0 U256))) [::] in

  (* tmp = rsp; *)
  let i1 := Lopn [:: Lvar tmpi ] (Ox86 (MOV U64)) [:: Pvar rsp ] in

  (* tmp &= - (wsize_size x86_cs_max_ws); *)
  let i2 :=
    Lopn
      (flags_lv ++ [:: Lvar tmpi ])
      (Ox86 (AND U64))
      [:: Pvar tmp; pword_of_int U64 (- wsize_size x86_cs_max_ws)%Z ]
  in

  map (MkLI dummy_instr_info) [:: i0; i1; i2 ].

Lemma init_code_unrolledP lp fn lfd lc1 lc2 :
  get_fundef lp.(lp_funcs) fn = Some lfd ->
  lfd.(lfd_body) = lc1 ++ init_code_unrolled ++ lc2 ->
  forall scs m vm,
  get_gvar [::] vm rsp = ok (Vword (top_stack m)) ->
  exists vm',
    lsem lp (Lstate scs m vm fn (size lc1))
            (Lstate scs m vm' fn (size lc1 + size init_code_unrolled)) /\
    vm' = vm.[vlri <- ok (pword_of_word 0%R)]
            .[tmpi <- ok (pword_of_word (align_word x86_cs_max_ws (top_stack m)))]
          [\ sv_of_list to_var rflags].
Proof.
  move=> hlfd hbody scs m vm hrsp.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc1 ++ init_code_unrolled ++ lc2).
  + by exists lfd.
  eexists _; split.
  + apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -(addn0 (size lc1)) (find_instr_skip hlinear) /=.
      by rewrite /eval_instr /= /of_estate /with_vm /=.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite get_gvar_neq // hrsp /= zero_extend_u.
      by rewrite /of_estate /with_vm /=.
    apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite -addnS (find_instr_skip hlinear) /=.
    rewrite /eval_instr /= /sem_sopn /=.
    rewrite (@get_gvar_eq _ tmp) //=.
    rewrite /of_estate /with_vm /= !zero_extend_u.
    by rewrite -addnS.
  move=> v hnin.
  rewrite !Fv.setP.
  case: eqP => [|_].
  + move=> ?; subst v.
    by rewrite pword_of_wordE.
  do 5 (case: eqP => [|_]; first by (move=> ?; subst v; case: hnin; apply /Sv_memP)).
  case: eqP => //.
  move=> ?; subst v.
  by rewrite pword_of_wordE.
Qed.

Section WHILE.

Context (max_stk_size : Z).

Definition init_code_loop lbl : lcmd :=
  (* ymm = #set0_256(); *)
  let i0 := Lopn [:: Lvar vlri ] (Oasm (ExtOp (Oset0 U256))) [::] in

  (* tmp = rsp; *)
  let i1 := Lopn [:: Lvar tmpi ] (Ox86 (MOV U64)) [:: Pvar rsp ] in

  (* tmp &= - (wsize_size x86_cs_max_ws); *)
  let i2 :=
    Lopn
      (flags_lv ++ [:: Lvar tmpi ])
      (Ox86 (AND U64))
      [:: Pvar tmp; pword_of_int U64 (- wsize_size x86_cs_max_ws)%Z ]
  in

  (* off = -max_stk_size; *)
  let i3 :=
    Lopn
      [:: Lvar offi ]
      (Ox86 (MOV U64))
      [:: pword_of_int U64 (- max_stk_size)%Z ]
  in

  (* l1: *)
  let i4 := Llabel lbl in

  map (MkLI dummy_instr_info) [:: i0; i1; i2; i3; i4 ].

Lemma init_code_loopP lp fn lfd lc1 lc2 lbl :
  get_fundef lp.(lp_funcs) fn = Some lfd ->
  lfd.(lfd_body) = lc1 ++ init_code_loop lbl ++ lc2 ->
  forall scs m vm,
  get_gvar [::] vm rsp = ok (Vword (top_stack m)) ->
  exists vm',
    lsem lp (Lstate scs m vm fn (size lc1))
            (Lstate scs m vm' fn (size lc1 + size (init_code_loop lbl))) /\
    vm' = vm.[vlri <- ok (pword_of_word 0%R)]
            .[tmpi <- ok (pword_of_word (align_word x86_cs_max_ws (top_stack m)))]
            .[offi <- ok (pword_of_word (wrepr Uptr (- max_stk_size)))]
          [\ sv_of_list to_var rflags].
Proof.
  move=> hlfd hbody scs m vm hrsp.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc1 ++ (init_code_loop lbl) ++ lc2).
  + by exists lfd.
  eexists _; split.
  + apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -(addn0 (size lc1)) (find_instr_skip hlinear) /=.
      by rewrite /eval_instr /= /of_estate /= pword_of_wordE.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite get_gvar_neq // hrsp /= zero_extend_u pword_of_wordE.
      by rewrite /of_estate /=.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite (@get_gvar_eq _ tmp) /=; last by [].
      by rewrite /of_estate /= !zero_extend_u pword_of_wordE.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /of_estate /= zero_extend_u pword_of_wordE.
      by rewrite -addnS.
    apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite (find_instr_skip hlinear) /=.
    rewrite /eval_instr /= /setpc /=.
    by rewrite -addnS.
  move=> v hnin.
  rewrite !Fv.setP.
  case: eqP => [//|_].
  case: eqP => [//|_].
  do 5 (case: eqP => [|_]; first by (move=> ?; subst v; case: hnin; apply /Sv_memP)).
  done.
Qed.
*)
Lemma read0 ws x :
  @LE.wread8 ws 0 x = 0%R.
Proof.
  rewrite /LE.wread8 /LE.encode /split_vec.
  case: (Nat.le_gt_cases (ws %/ U8 + ws %% U8) (Z.to_nat x)) => h0.
  + rewrite nth_default; first done. rewrite size_map size_iota. by apply/leP.

  rewrite (nth_map 0); first last.
  + rewrite size_iota. by apply/ltP.
  rewrite /word.subword /= Z.shiftr_0_l Zmod_0_l.
  f_equal.
  by apply /(@eqP (word U8)).
Qed.

Section toto.
Context (lp : lprog) (fn : funname) (lfd : lfundef) (lc : lcmd) (lbl : label.label).
Context (ws_align : wsize) (ws : wsize) (max_stk_size : Z).
Context (halign : is_align max_stk_size ws).
Context (le_ws_ws_align : (ws <= ws_align)%CMP).
Context (hlfd : get_fundef lp.(lp_funcs) fn = Some lfd).
Context (hlabel : ~~ has (is_label lbl) lc).

Context (lt_0_max_stk_size : (0 < max_stk_size)%Z).

Section LARGE.

Context (hlarge : ~ (ws <= U64)%CMP).
Context (hbody : lfd.(lfd_body) = lc ++ x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size).
Context (ptr : pointer).
Context (hstack : (max_stk_size <= wunsigned (align_word ws_align ptr))%Z).
Let top := (align_word ws_align ptr - wrepr Uptr max_stk_size)%R.

Section S1.

Context (s1 : estate).
Context (hrsp : get_gvar [::] s1.(evm) rsp = ok (Vword ptr)).

Record state_rel_small vars s2 n := {
  sr_scs : s1.(escs) = s2.(escs);
  sr_mem : mem_equiv s1.(emem) s2.(emem);
  sr_mem_valid : forall p, between top max_stk_size p U8 -> validw s2.(emem) p U8;
  sr_disjoint :
    forall p, disjoint_zrange top max_stk_size p (wsize_size U8) ->
      read s1.(emem) p U8 = read s2.(emem) p U8;
  sr_clear : forall p,
    between top (max_stk_size + n) p U8 -> read s2.(emem) p U8 = ok 0%R;
  sr_vm : s1.(evm) = s2.(evm) [\ vars];
  sr_tmp : get_var s2.(evm) tmpi = ok (Vword (align_word ws_align ptr));
  sr_off : get_var s2.(evm) offi = ok (Vword (wrepr Uptr n));
  sr_aligned : is_align n ws;
  sr_bound : (- max_stk_size <= n <= 0)%Z;
}.

Record state_rel c s2 n := {
  sr_vlr : get_var s2.(evm) vlri = ok (@Vword ws 0);
  sr_srs :> state_rel_small c s2 n
}.

Lemma loop_bodyP s2 n :
  state_rel (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s2 n ->
  (n < 0)%Z ->
  exists s3,
    [/\ lsem lp (of_estate s2 fn (size lc + 5))
                (of_estate s3 fn (size lc + 7)),
        get_var s3.(evm) zfi = ok (Vbool (ZF_of_word (wrepr U64 n + wrepr U64 (wsize_size ws))))
      & state_rel (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s3 (n + wsize_size ws)].
Proof.
  move=> hsr hlt.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have: validw (emem s2) (align_word ws_align ptr + wrepr Uptr n)%R ws.
  + apply /validwP; split.
    + apply is_align_add.
      + apply (is_align_m le_ws_ws_align).
        by apply do_align_is_align.
      rewrite WArray.arr_is_align.
      by apply hsr.(sr_aligned).
    move=> k hk.
    apply hsr.(sr_mem_valid).
    rewrite /between /zbetween addE /top !zify.
    rewrite -GRing.addrA -wrepr_add.
    have hbound := hsr.(sr_bound).
    assert (h := wunsigned_range (align_word ws_align ptr)).
    have hn: (n <= - wsize_size ws)%Z.
    + have := hsr.(sr_aligned).
      rewrite /is_align WArray.p_to_zE.
      move=> /eqP /Z.mod_divide [//|m ?].
      have: (m < 0)%Z; Lia.nia.
    rewrite wunsigned_sub; last first.
    + by move: h hstack => /=; Lia.lia.
    rewrite wunsigned_add; last first.
    + by move: h hstack => /=; Lia.lia.
    rewrite wsize8. Lia.lia.
  move=> /(writeV 0) [m' hm'].
  eexists (Estate _ _ _); split=> /=.
  + apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite /get_gvar hsr.(sr_vlr) /=.
      have: exec_sopn (spp:=mk_spp) (Ox86 (VMOVDQU ws)) [:: @Vword ws 0] = ok [:: @Vword ws 0%R].
      + case: ws hlarge => //= _.
        rewrite /exec_sopn /=. rewrite zero_extend_u. done.
        rewrite /exec_sopn /=. rewrite zero_extend_u. done.
      move=> -> /=.
      rewrite hsr.(sr_tmp) /=.
      rewrite /get_gvar hsr.(sr_off) /=.
      rewrite !zero_extend_u.
      rewrite truncate_word_u /=.
      rewrite hm' /=.
      by rewrite /of_estate /=.
    apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite -addnS (find_instr_skip hlinear) /=.
    rewrite /eval_instr /= /sem_sopn /=.
    rewrite /get_gvar hsr.(sr_off) /=.
    rewrite /of_estate /= !zero_extend_u pword_of_wordE.
    by rewrite -addnS.
  + rewrite get_var_neq //.
    by rewrite get_var_eq.
  case: hsr => hvlr [hscs hmem hvalid hdisj hclear hvm htmp hoff haligned hbound].
  split=> //=.
  + by rewrite !get_var_neq.
  split=> //=.
  + apply (mem_equiv_trans hmem).
    split.
    + by apply (Memory.write_mem_stable hm').
    by move=> ??; symmetry; apply (write_validw_eq hm').
  + move=> p hb.
    rewrite (write_validw_eq hm').
    by apply hvalid.
  + move=> p hp.
    rewrite (writeP_neq hm'); first by apply hdisj.
    apply: disjoint_zrange_incl_l hp.
    rewrite /top /zbetween !zify.
    assert (h := wunsigned_range (align_word ws_align ptr)).
    have hn: (n <= - wsize_size ws)%Z.
    + move: haligned.
      rewrite /is_align WArray.p_to_zE.
      move=> /eqP /Z.mod_divide [//|m ?].
      have ? := wsize_size_pos ws.
      have: (m < 0)%Z; Lia.nia.
    rewrite wunsigned_sub; last first.
    + move: h hstack => /=; Lia.lia.
    rewrite wunsigned_add; last first.
    + move: h hstack => /=; Lia.lia.
    Lia.lia.
  + move=> p hb.
    rewrite (write_read8 hm') subE /=.
    case: ifPn.
    + move=> _. by rewrite read0.
    move=> h.
    apply hclear.
    (* je n'ai pas tout compris à la preuve *)
    move: h hb; rewrite /between /zbetween /top.
    rewrite !zify wsize8.
    rewrite wunsigned_sub; last first.
    + assert (h := wunsigned_range (align_word ws_align ptr)). simpl in *. Lia.lia.
    rewrite wunsigned_sub_if.
    rewrite wunsigned_add; last first.
    + assert (h := wunsigned_range (align_word ws_align ptr)). simpl in *. Lia.lia.
    case: ZleP=> [_|? _] /=; Lia.lia.
  + do 6 (rewrite vmap_eq_except_set; last by apply /Sv_memP).
    done.
  + by rewrite !get_var_neq.
  + rewrite get_var_eq /=.
    by rewrite wrepr_add.
  + move: haligned.
    rewrite /is_align !WArray.p_to_zE.
    rewrite Zplus_mod.
    move=> /eqP -> /=.
    by rewrite Z_mod_same_full.
  have hn: (n <= - wsize_size ws)%Z.
  + move: haligned.
    rewrite /is_align WArray.p_to_zE.
    move=> /eqP /Z.mod_divide [//|m ?].
    have ? := wsize_size_pos ws.
    have: (m < 0)%Z; Lia.nia.
  have := wsize_size_pos ws.
  by Lia.lia.
Qed.

Lemma loopP s2 n :
  state_rel (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s2 n ->
  (n < 0)%Z ->
  exists s3,
    [/\ lsem lp (of_estate s2 fn (size lc + 5))
                (of_estate s3 fn (size lc + 8))
      & state_rel (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s3 0].
Proof.
  move=> hsr hlt.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have [k hn]: (exists k, n = - Z.of_nat k * wsize_size ws)%Z.
  + have := hsr.(sr_aligned).
    rewrite /is_align WArray.p_to_zE.
    move=> /eqP /Z.mod_divide [//|m ?].
    exists (Z.to_nat (-m)).
    rewrite Z2Nat.id; first by rewrite Z.opp_involutive.
    have := wsize_size_pos ws.
    Lia.lia.
  elim: k n s2 hsr hlt hn => [|k ih] n s2 hsr hlt hn.
  + move: hn; rewrite Z.mul_0_l.
    Lia.lia.
  have [s3 [hsem3 hzf3 hsr3]] := loop_bodyP hsr hlt.
  case hzf: (~~ ZF_of_word (wrepr U64 n + wrepr U64 (wsize_size ws))).
  + have hn3: (n + wsize_size ws < 0)%Z.
    + case: k {ih} hn => [|k].
      + rewrite Z.mul_opp_l Z.mul_1_l => hn.
        case /negP: hzf.
        by rewrite /ZF_of_word -wrepr_add hn Z.add_opp_diag_l.
      have := wsize_size_pos ws.
      Lia.lia.
    have := ih _ _ hsr3 hn3.
    move=> /(_ ltac:(Lia.lia)).
    move=> [s4 [hsem4 hsr4]].
    exists s4; split=> //.
    apply: (lsem_trans hsem3).
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite (find_instr_skip hlinear) /=.
      rewrite /eval_instr /=.
      rewrite /get_gvar hzf3 /= hzf hlfd /=.
      rewrite hbody.
      rewrite (find_label_cat_hd (spp:=mk_spp) _ hlabel).
      do 5 rewrite (find_labelE (spp:=mk_spp)) /=.
      rewrite /is_label /= eq_refl /=.
      by rewrite /setcpc /=.
    rewrite -addnS.
    by apply hsem4.
  have hn3: (n + wsize_size ws = 0)%Z.
  + have hb3 := hsr3.(sr_bound).
    case: (Z.le_gt_cases 0 (n + wsize_size ws)); first by Lia.lia.
    move=> hn'.
    have := @wunsigned_repr_small U64 (wbase U64 + n + wsize_size ws).
    rewrite -Z.add_assoc wrepr_add. rewrite wreprB.
    move /(elimNf idP): hzf.
    rewrite /ZF_of_word -wrepr_add => /eqP ->.
    have ?: (max_stk_size < wbase U64)%Z.
    + assert (h := wunsigned_range (align_word ws_align ptr)).
      move: h hstack => /=.
      Lia.lia.
    move=> /(_ ltac:(Lia.lia)).
    change (wunsigned (0 + 0)) with 0%Z.
    Lia.lia. (* proof ugly and probably too complex *)
  exists s3; split; last by rewrite -hn3.
  apply: (lsem_trans hsem3).
  apply: LSem_step.
  rewrite /lsem1 /step.
  rewrite (find_instr_skip hlinear) /=.
  rewrite /eval_instr /=.
  rewrite /get_gvar hzf3 /= hzf.
  rewrite /setpc /=.
  by rewrite -addnS.
Qed.

End S1.

Context (s0 : estate).
Context (hvalid : forall p,
  between top max_stk_size p U8 ->
  validw (emem s0) p U8).

Lemma init_code_loopP' :
  get_gvar [::] s0.(evm) rsp = ok (Vword ptr) ->
  exists s1,
    lsem lp (of_estate s0 fn (size lc)) (of_estate s1 fn (size lc + 5)) /\
    state_rel s0 (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s1 (-max_stk_size).
Proof.
  move=> hrsp.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have h256 := wsize_ge_U256 ws.
  eexists (Estate _ _ _); split.
  + apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -(addn0 (size lc)) (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /of_estate /to_estate /=.
      rewrite /sem_sopn /=.
      by rewrite hrsp /= zero_extend_u pword_of_wordE.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      have: exec_sopn (Oasm (ExtOp (Oset0 ws))) [::] = ok [:: @Vword ws 0].
      + rewrite /exec_sopn /= /sopn_sem /=.
        rewrite /Oset0_instr.
        move /negP/negPf : hlarge => -> /=. done.
      move=> -> /=.
      rewrite (sumbool_of_boolET h256).
      by rewrite /of_estate /=.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite get_gvar_neq //.
      rewrite (@get_gvar_eq _ tmp) /=; last by [].
      by rewrite /of_estate /= !zero_extend_u pword_of_wordE.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /of_estate /= zero_extend_u pword_of_wordE.
      by rewrite -addnS.
    apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite (find_instr_skip hlinear) /=.
    rewrite /eval_instr /= /setpc /=.
    rewrite /of_estate /=.
    by rewrite -addnS.
  split=> //=.
  + do 7 rewrite get_var_neq //.
    rewrite get_var_eq /=. done.
  split=> //=.
  + move=> p. rewrite /between /zbetween !zify wsize8. Lia.lia.
  + do 9 (rewrite vmap_eq_except_set; last by apply /Sv_memP).
    done.
  + rewrite get_var_neq //.
    rewrite get_var_eq /=. done.
  + rewrite get_var_eq. done.
  + move: halign.
    rewrite /is_align !WArray.p_to_zE.
    by move=> /eqP /Z_mod_zero_opp_full /eqP.
  Lia.lia.
Qed.

Lemma fullP_large :
  get_gvar [::] s0.(evm) rsp = ok (Vword ptr) ->
  exists s2,
    lsem lp (of_estate s0 fn (size lc)) (of_estate s2 fn (size lc + size (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)))
    /\ state_rel s0 (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s2 0.
Proof.
  move=> hrsp.
  have [s1 [hsem1 hsr1]] := init_code_loopP' hrsp.
  have [s2 [hsem2 hsr2]] := loopP hsr1 ltac:(Lia.lia).
  exists s2; split=> //.
  by apply: (lsem_trans hsem1).
Qed.

End LARGE.

Section SMALL.

Context (hsmall : (ws <= U64)%CMP).
Context (hbody : lfd.(lfd_body) = lc ++ x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size).
Context (ptr : pointer).
Context (hstack : (max_stk_size <= wunsigned (align_word ws_align ptr))%Z).
Let top := (align_word ws_align ptr - wrepr Uptr max_stk_size)%R.

Section S1.

Context (s1 : estate).
Context (hrsp : get_gvar [::] s1.(evm) rsp = ok (Vword ptr)).

Lemma loop_bodyP_small s2 n :
  state_rel_small ptr s1 (write_c (x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size)) s2 n ->
  (n < 0)%Z ->
  exists s3,
    [/\ lsem lp (of_estate s2 fn (size lc + 4))
                (of_estate s3 fn (size lc + 6)),
        get_var s3.(evm) zfi = ok (Vbool (ZF_of_word (wrepr U64 n + wrepr U64 (wsize_size ws))))
      & state_rel_small ptr s1 (write_c (x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size)) s3 (n + wsize_size ws)].
Proof.
  move=> hsr hlt.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have: validw (emem s2) (align_word ws_align ptr + wrepr Uptr n)%R ws.
  + apply /validwP; split.
    + apply is_align_add.
      + apply (is_align_m le_ws_ws_align).
        by apply do_align_is_align.
      rewrite WArray.arr_is_align.
      by apply hsr.(sr_aligned).
    move=> k hk.
    apply hsr.(sr_mem_valid).
    rewrite /between /zbetween addE /top !zify.
    rewrite -GRing.addrA -wrepr_add.
    have hbound := hsr.(sr_bound).
    assert (h := wunsigned_range (align_word ws_align ptr)).
    have hn: (n <= - wsize_size ws)%Z.
    + have := hsr.(sr_aligned).
      rewrite /is_align WArray.p_to_zE.
      move=> /eqP /Z.mod_divide [//|m ?].
      have: (m < 0)%Z; Lia.nia.
    rewrite wunsigned_sub; last first.
    + move: h hstack => /=; Lia.lia.
    rewrite wunsigned_add; last first.
    + move: h hstack => /=. Lia.lia.
    rewrite wsize8. Lia.lia.
  move=> /(writeV 0) [m' hm'].
  eexists (Estate _ _ _); split=> /=.
  + apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      have: exec_sopn (spp:=mk_spp) (Ox86 (MOV ws)) [:: @Vword ws 0] = ok [:: @Vword ws 0%R].
      + case: ws hsmall => //= _.
        rewrite /exec_sopn /=. rewrite zero_extend_u. done.
        rewrite /exec_sopn /=. rewrite zero_extend_u. done.
        rewrite /exec_sopn /=. rewrite zero_extend_u. done.
        rewrite /exec_sopn /=. rewrite zero_extend_u. done.
      rewrite wrepr0.
      move=> -> /=.
      rewrite hsr.(sr_tmp) /=.
      rewrite /get_gvar hsr.(sr_off) /=.
      rewrite !zero_extend_u.
      rewrite truncate_word_u /=.
      rewrite hm' /=.
      by rewrite /of_estate /=.
    apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite -addnS (find_instr_skip hlinear) /=.
    rewrite /eval_instr /= /sem_sopn /=.
    rewrite /get_gvar hsr.(sr_off) /=.
    rewrite /of_estate /= !zero_extend_u pword_of_wordE.
    by rewrite -addnS.
  + rewrite get_var_neq //.
    by rewrite get_var_eq.
  case: hsr => hscs hmem hvalid hdisj hclear hvm htmp hoff haligned hbound.
  split=> //=.
  + apply (mem_equiv_trans hmem).
    split.
    + by apply (Memory.write_mem_stable hm').
    by move=> ??; symmetry; apply (write_validw_eq hm').
  + move=> p hb.
    rewrite (write_validw_eq hm').
    by apply hvalid.
  + move=> p hp.
    rewrite (writeP_neq hm'); first by apply hdisj.
    apply: disjoint_zrange_incl_l hp.
    rewrite /top /zbetween !zify.
    assert (h := wunsigned_range (align_word ws_align ptr)).
    have hn: (n <= - wsize_size ws)%Z.
    + move: haligned.
      rewrite /is_align WArray.p_to_zE.
      move=> /eqP /Z.mod_divide [//|m ?].
      have ? := wsize_size_pos ws.
      have: (m < 0)%Z; Lia.nia.
    rewrite wunsigned_sub; last first.
    + move: h hstack => /=; Lia.lia.
    rewrite wunsigned_add; last first.
    + move: h hstack => /=. Lia.lia.
    simpl; Lia.lia.
  + move=> p hb.
    rewrite (write_read8 hm') subE /=.
    case: ifPn.
    + move=> _. by rewrite read0.
    move=> h.
    apply hclear.
    (* je n'ai pas tout compris à la preuve *)
    move: h hb; rewrite /between /zbetween /top.
    rewrite !zify wsize8.
    rewrite wunsigned_sub; last first.
    + assert (h := wunsigned_range (align_word ws_align ptr)). simpl in *. Lia.lia.
    rewrite wunsigned_sub_if.
    rewrite wunsigned_add; last first.
    + assert (h := wunsigned_range (align_word ws_align ptr)). simpl in *. Lia.lia.
    case: ZleP=> [_|? _] /=; Lia.lia.
  + do 6 (rewrite vmap_eq_except_set; last by apply /Sv_memP).
    done.
  + by rewrite !get_var_neq.
  + rewrite get_var_eq /=.
    by rewrite wrepr_add.
  + move: haligned.
    rewrite /is_align !WArray.p_to_zE.
    rewrite Zplus_mod.
    move=> /eqP -> /=.
    by rewrite Z_mod_same_full.
  have hn: (n <= - wsize_size ws)%Z.
  + move: haligned.
    rewrite /is_align WArray.p_to_zE.
    move=> /eqP /Z.mod_divide [//|m ?].
    have ? := wsize_size_pos ws.
    have: (m < 0)%Z; Lia.nia.
  have := wsize_size_pos ws.
  by Lia.lia.
Qed.

Lemma loopP_small s2 n :
  state_rel_small ptr s1 (write_c (x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size)) s2 n ->
  (n < 0)%Z ->
  exists s3,
    [/\ lsem lp (of_estate s2 fn (size lc + 4))
                (of_estate s3 fn (size lc + 7))
      & state_rel_small ptr s1 (write_c (x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size)) s3 0].
Proof.
  move=> hsr hlt.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have [k hn]: (exists k, n = - Z.of_nat k * wsize_size ws)%Z.
  + have := hsr.(sr_aligned).
    rewrite /is_align WArray.p_to_zE.
    move=> /eqP /Z.mod_divide [//|m ?].
    exists (Z.to_nat (-m)).
    rewrite Z2Nat.id; first by rewrite Z.opp_involutive.
    have := wsize_size_pos ws.
    Lia.lia.
  elim: k n s2 hsr hlt hn => [|k ih] n s2 hsr hlt hn.
  + move: hn; rewrite Z.mul_0_l.
    Lia.lia.
  have [s3 [hsem3 hzf3 hsr3]] := loop_bodyP_small hsr hlt.
  case hzf: (~~ ZF_of_word (wrepr U64 n + wrepr U64 (wsize_size ws))).
  + have hn3: (n + wsize_size ws < 0)%Z.
    + case: k {ih} hn => [|k].
      + rewrite Z.mul_opp_l Z.mul_1_l => hn.
        case /negP: hzf.
        by rewrite /ZF_of_word -wrepr_add hn Z.add_opp_diag_l.
      have := wsize_size_pos ws.
      Lia.lia.
    have := ih _ _ hsr3 hn3.
    move=> /(_ ltac:(Lia.lia)).
    move=> [s4 [hsem4 hsr4]].
    exists s4; split=> //.
    apply: (lsem_trans hsem3).
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite (find_instr_skip hlinear) /=.
      rewrite /eval_instr /=.
      rewrite /get_gvar hzf3 /= hzf hlfd /=.
      rewrite hbody.
      rewrite (find_label_cat_hd (spp:=mk_spp) _ hlabel).
      do 4 rewrite (find_labelE (spp:=mk_spp)) /=.
      rewrite /is_label /= eq_refl /=.
      by rewrite /setcpc /=.
    rewrite -addnS.
    by apply hsem4.
  have hn3: (n + wsize_size ws = 0)%Z.
  + have hb3 := hsr3.(sr_bound).
    case: (Z.le_gt_cases 0 (n + wsize_size ws)); first by Lia.lia.
    move=> hn'.
    have := @wunsigned_repr_small U64 (wbase U64 + n + wsize_size ws).
    rewrite -Z.add_assoc wrepr_add. rewrite wreprB.
    move /(elimNf idP): hzf.
    rewrite /ZF_of_word -wrepr_add => /eqP ->.
    have ?: (max_stk_size < wbase U64)%Z.
    + assert (h := wunsigned_range (align_word ws_align ptr)).
      move: h hstack => /=.
      Lia.lia.
    move=> /(_ ltac:(Lia.lia)).
    change (wunsigned (0 + 0)) with 0%Z.
    Lia.lia. (* proof ugly and probably too complex *)
  exists s3; split; last by rewrite -hn3.
  apply: (lsem_trans hsem3).
  apply: LSem_step.
  rewrite /lsem1 /step.
  rewrite (find_instr_skip hlinear) /=.
  rewrite /eval_instr /=.
  rewrite /get_gvar hzf3 /= hzf.
  rewrite /setpc /=.
  by rewrite -addnS.
Qed.

End S1.

Context (s0 : estate).
Context (hvalid : forall p,
  between top max_stk_size p U8 ->
  validw (emem s0) p U8).

Lemma init_code_loopP'_small :
  get_gvar [::] s0.(evm) rsp = ok (Vword ptr) ->
  exists s1,
    lsem lp (of_estate s0 fn (size lc)) (of_estate s1 fn (size lc + 4)) /\
    state_rel_small ptr s0 (write_c (x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size)) s1 (-max_stk_size).
Proof.
  move=> hrsp.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have h256 := wsize_ge_U256 ws.
  eexists (Estate _ _ _); split.
  + apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -(addn0 (size lc)) (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite hrsp /= zero_extend_u pword_of_wordE.
      by rewrite /of_estate /=.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite (@get_gvar_eq _ tmp) /=; last by [].
      by rewrite /of_estate /= !zero_extend_u pword_of_wordE.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /of_estate /= zero_extend_u pword_of_wordE.
      by rewrite -addnS.
    apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite (find_instr_skip hlinear) /=.
    rewrite /eval_instr /= /setpc /=.
    rewrite /of_estate /=.
    by rewrite -addnS.
  split=> //=.
  + move=> p; rewrite /between /zbetween !zify wsize8; Lia.lia.
  + do 8 (rewrite vmap_eq_except_set; last by apply /Sv_memP).
    done.
  + rewrite get_var_neq //.
    rewrite get_var_eq /=. done.
  + rewrite get_var_eq. done.
  + move: halign.
    rewrite /is_align !WArray.p_to_zE.
    by move=> /eqP /Z_mod_zero_opp_full /eqP.
  Lia.lia.
Qed.

Lemma fullP_small :
  get_gvar [::] s0.(evm) rsp = ok (Vword ptr) ->
  exists s2,
    lsem lp (of_estate s0 fn (size lc)) (of_estate s2 fn (size lc + size (x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size)))
    /\ state_rel_small ptr s0 (write_c (x86_clear_stack_loop_small rspi lbl ws_align ws max_stk_size)) s2 0.
Proof.
  move=> hrsp.
  have [s1 [hsem1 hsr1]] := init_code_loopP'_small hrsp.
  have [s2 [hsem2 hsr2]] := loopP_small hsr1 ltac:(Lia.lia).
  exists s2; split=> //.
  by apply: (lsem_trans hsem1).
Qed.

End SMALL.

Context (hbody : lfd.(lfd_body) = lc ++ x86_clear_stack_loop rspi lbl ws_align ws max_stk_size).
Context (s0 : estate) (ptr : pointer).
Context (hstack : (max_stk_size <= wunsigned (align_word ws_align ptr))%Z).
Context (hvalid : forall p,
  between (align_word ws_align ptr - wrepr U64 max_stk_size) max_stk_size p U8 ->
  validw (emem s0) p U8).

Lemma fullP :
  get_gvar [::] s0.(evm) rsp = ok (Vword ptr) ->
  exists s2,
    lsem lp (of_estate s0 fn (size lc)) (of_estate s2 fn (size lc + size (x86_clear_stack_loop rspi lbl ws_align ws max_stk_size)))
    /\ state_rel_small ptr s0 (write_c (x86_clear_stack_loop rspi lbl ws_align ws max_stk_size)) s2 0.
Proof.
  move=> hget.
  move: hbody.
  rewrite /x86_clear_stack_loop.
  case: ifP.
  + move=> hbody' hsmall.
    by apply fullP_small.
  move=> /(elimF idP) h1 h2.
  have [s2 [hsem hsr]] := fullP_large h1 h2 hstack hvalid hget.
  exists s2; split => //.
  by case: hsr.
Qed.

End toto.

Section Unrolled.

Section toto.
Context (lp : lprog) (fn : funname) (lfd : lfundef) (lc : lcmd).
Context (ws_align : wsize) (ws : wsize) (max_stk_size : Z).
Context (halign : is_align max_stk_size ws).
Context (le_ws_ws_align : (ws <= ws_align)%CMP).
Context (hlfd : get_fundef lp.(lp_funcs) fn = Some lfd).

Context (lt_0_max_stk_size : (0 < max_stk_size)%Z).

Section LARGE.

Context (hlarge : ~ (ws <= U64)%CMP).
Context (hbody : lfd.(lfd_body) = lc ++ x86_clear_stack_unrolled_large rspi ws_align ws max_stk_size).
Context (ptr : pointer).
Context (hstack : (max_stk_size <= wunsigned (align_word ws_align ptr))%Z).
Let top := (align_word ws_align ptr - wrepr Uptr max_stk_size)%R.

Section S1.

Context (s1 : estate).
Context (hrsp : get_gvar [::] s1.(evm) rsp = ok (Vword ptr)).

Lemma loop_bodyP s2 n :
  state_rel ws_align ws max_stk_size ptr s1 (write_c (x86_clear_stack_unrolled_large rspi ws_align ws max_stk_size)) s2 (-max_stk_size + Z.of_nat n * wsize_size ws) ->
(*   (- max_stk_size + Z.of_nat (n.+1) * wsize_size ws <= 0)%Z -> *)
n < Z.to_nat ((max_stk_size - 1) / wsize_size ws + 1) ->
  exists s3,
    [/\ lsem lp (of_estate s2 fn (size lc + 3 + n))
                (of_estate s3 fn (size lc + 3 + n.+1)),
        get_var s3.(evm) zfi = ok (Vbool (ZF_of_word (wrepr U64 n + wrepr U64 (wsize_size ws))))
      & state_rel ws_align ws max_stk_size ptr s1 (write_c (x86_clear_stack_unrolled_large rspi ws_align ws max_stk_size)) s3 (n + wsize_size ws)].
Proof.
  move=> hsr hlt.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_unrolled_large rspi ws_align ws max_stk_size).
  + by exists lfd.
  have: validw (emem s2) (align_word ws_align ptr + wrepr Uptr (-max_stk_size + Z.of_nat n * wsize_size ws))%R ws.
  + apply /validwP; split.
    + apply is_align_add.
      + apply (is_align_m le_ws_ws_align).
        by apply do_align_is_align.
      rewrite WArray.arr_is_align.
      by apply hsr.(sr_aligned).
    move=> k hk.
    apply hsr.(sr_mem_valid).
    rewrite /between /zbetween addE /top !zify.
    rewrite -GRing.addrA -wrepr_add.
    have hbound := hsr.(sr_bound).
    assert (h := wunsigned_range (align_word ws_align ptr)). (*
    have hn: (n <= - wsize_size ws)%Z.
    + have := hsr.(sr_aligned).
      rewrite /is_align WArray.p_to_zE.
      move=> /eqP /Z.mod_divide [//|m ?].
      have: (m < 0)%Z; Lia.nia. *)
    rewrite wunsigned_sub; last first.
    + by move: h hstack => /=; Lia.lia.
    rewrite wunsigned_add; last first.
    + have := wsize_size_pos ws. Search "/" Nat.mul. by move: h hstack => /=; Lia.lia.
    rewrite wsize8. Lia.lia.
  move=> /(writeV 0) [m' hm'].
  eexists (Estate _ _ _); split=> /=.
  + apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite -addnA.
    rewrite (find_instr_skip hlinear) /=.
    rewrite oseq.onth_nth.
    rewrite (nth_map {| li_ii := dummy_instr_info; li_i := Lalign |}); last first.
    rewrite !size_map. rewrite size_iota.
    have := wsize_size_pos ws. Lia.lia. n
    2: simpl.
    nth map
    
    rewrite (oseq.onth_cat [::_; _; _]). rewrite -/(map _ _).
    case: ltP.
    + move=> /=. rewrite -plusE. Lia.lia.
    move=> _ /=.
    Search oseq.onth nth cat map nth ziota
    rewrite /eval_instr /= /sem_sopn /=.
    rewrite /get_gvar hsr.(sr_off) /=.
    rewrite /of_estate /= !zero_extend_u pword_of_wordE.
    by rewrite -addnS.
  + rewrite get_var_neq //.
    by rewrite get_var_eq.
  case: hsr => hvlr [hscs hmem hvalid hdisj hclear hvm htmp hoff haligned hbound].
  split=> //=.
  + by rewrite !get_var_neq.
  split=> //=.
  + apply (mem_equiv_trans hmem).
    split.
    + by apply (Memory.write_mem_stable hm').
    by move=> ??; symmetry; apply (write_validw_eq hm').
  + move=> p hb.
    rewrite (write_validw_eq hm').
    by apply hvalid.
  + move=> p hp.
    rewrite (writeP_neq hm'); first by apply hdisj.
    apply: disjoint_zrange_incl_l hp.
    rewrite /top /zbetween !zify.
    assert (h := wunsigned_range (align_word ws_align ptr)).
    have hn: (n <= - wsize_size ws)%Z.
    + move: haligned.
      rewrite /is_align WArray.p_to_zE.
      move=> /eqP /Z.mod_divide [//|m ?].
      have ? := wsize_size_pos ws.
      have: (m < 0)%Z; Lia.nia.
    rewrite wunsigned_sub; last first.
    + move: h hstack => /=; Lia.lia.
    rewrite wunsigned_add; last first.
    + move: h hstack => /=; Lia.lia.
    Lia.lia.
  + move=> p hb.
    rewrite (write_read8 hm') subE /=.
    case: ifPn.
    + move=> _. by rewrite read0.
    move=> h.
    apply hclear.
    (* je n'ai pas tout compris à la preuve *)
    move: h hb; rewrite /between /zbetween /top.
    rewrite !zify wsize8.
    rewrite wunsigned_sub; last first.
    + assert (h := wunsigned_range (align_word ws_align ptr)). simpl in *. Lia.lia.
    rewrite wunsigned_sub_if.
    rewrite wunsigned_add; last first.
    + assert (h := wunsigned_range (align_word ws_align ptr)). simpl in *. Lia.lia.
    case: ZleP=> [_|? _] /=; Lia.lia.
  + do 6 (rewrite vmap_eq_except_set; last by apply /Sv_memP).
    done.
  + by rewrite !get_var_neq.
  + rewrite get_var_eq /=.
    by rewrite wrepr_add.
  + move: haligned.
    rewrite /is_align !WArray.p_to_zE.
    rewrite Zplus_mod.
    move=> /eqP -> /=.
    by rewrite Z_mod_same_full.
  have hn: (n <= - wsize_size ws)%Z.
  + move: haligned.
    rewrite /is_align WArray.p_to_zE.
    move=> /eqP /Z.mod_divide [//|m ?].
    have ? := wsize_size_pos ws.
    have: (m < 0)%Z; Lia.nia.
  have := wsize_size_pos ws.
  by Lia.lia.
Qed.

Lemma loopP s2 n :
  state_rel (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s2 n ->
  (n < 0)%Z ->
  exists s3,
    [/\ lsem lp (of_estate s2 fn (size lc + 5))
                (of_estate s3 fn (size lc + 8))
      & state_rel (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s3 0].
Proof.
  move=> hsr hlt.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have [k hn]: (exists k, n = - Z.of_nat k * wsize_size ws)%Z.
  + have := hsr.(sr_aligned).
    rewrite /is_align WArray.p_to_zE.
    move=> /eqP /Z.mod_divide [//|m ?].
    exists (Z.to_nat (-m)).
    rewrite Z2Nat.id; first by rewrite Z.opp_involutive.
    have := wsize_size_pos ws.
    Lia.lia.
  elim: k n s2 hsr hlt hn => [|k ih] n s2 hsr hlt hn.
  + move: hn; rewrite Z.mul_0_l.
    Lia.lia.
  have [s3 [hsem3 hzf3 hsr3]] := loop_bodyP hsr hlt.
  case hzf: (~~ ZF_of_word (wrepr U64 n + wrepr U64 (wsize_size ws))).
  + have hn3: (n + wsize_size ws < 0)%Z.
    + case: k {ih} hn => [|k].
      + rewrite Z.mul_opp_l Z.mul_1_l => hn.
        case /negP: hzf.
        by rewrite /ZF_of_word -wrepr_add hn Z.add_opp_diag_l.
      have := wsize_size_pos ws.
      Lia.lia.
    have := ih _ _ hsr3 hn3.
    move=> /(_ ltac:(Lia.lia)).
    move=> [s4 [hsem4 hsr4]].
    exists s4; split=> //.
    apply: (lsem_trans hsem3).
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite (find_instr_skip hlinear) /=.
      rewrite /eval_instr /=.
      rewrite /get_gvar hzf3 /= hzf hlfd /=.
      rewrite hbody.
      rewrite (find_label_cat_hd (spp:=mk_spp) _ hlabel).
      do 5 rewrite (find_labelE (spp:=mk_spp)) /=.
      rewrite /is_label /= eq_refl /=.
      by rewrite /setcpc /=.
    rewrite -addnS.
    by apply hsem4.
  have hn3: (n + wsize_size ws = 0)%Z.
  + have hb3 := hsr3.(sr_bound).
    case: (Z.le_gt_cases 0 (n + wsize_size ws)); first by Lia.lia.
    move=> hn'.
    have := @wunsigned_repr_small U64 (wbase U64 + n + wsize_size ws).
    rewrite -Z.add_assoc wrepr_add. rewrite wreprB.
    move /(elimNf idP): hzf.
    rewrite /ZF_of_word -wrepr_add => /eqP ->.
    have ?: (max_stk_size < wbase U64)%Z.
    + assert (h := wunsigned_range (align_word ws_align ptr)).
      move: h hstack => /=.
      Lia.lia.
    move=> /(_ ltac:(Lia.lia)).
    change (wunsigned (0 + 0)) with 0%Z.
    Lia.lia. (* proof ugly and probably too complex *)
  exists s3; split; last by rewrite -hn3.
  apply: (lsem_trans hsem3).
  apply: LSem_step.
  rewrite /lsem1 /step.
  rewrite (find_instr_skip hlinear) /=.
  rewrite /eval_instr /=.
  rewrite /get_gvar hzf3 /= hzf.
  rewrite /setpc /=.
  by rewrite -addnS.
Qed.

End S1.

Context (s0 : estate).
Context (hvalid : forall p,
  between top max_stk_size p U8 ->
  validw (emem s0) p U8).

Lemma init_code_loopP' :
  get_gvar [::] s0.(evm) rsp = ok (Vword ptr) ->
  exists s1,
    lsem lp (of_estate s0 fn (size lc)) (of_estate s1 fn (size lc + 5)) /\
    state_rel s0 (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s1 (-max_stk_size).
Proof.
  move=> hrsp.
  have hlinear: is_linear_of (spp := mk_spp) lp fn (lc ++ x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size).
  + by exists lfd.
  have h256 := wsize_ge_U256 ws.
  eexists (Estate _ _ _); split.
  + apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -(addn0 (size lc)) (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /of_estate /to_estate /=.
      rewrite /sem_sopn /=.
      by rewrite hrsp /= zero_extend_u pword_of_wordE.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      have: exec_sopn (Oasm (ExtOp (Oset0 ws))) [::] = ok [:: @Vword ws 0].
      + rewrite /exec_sopn /= /sopn_sem /=.
        rewrite /Oset0_instr.
        move /negP/negPf : hlarge => -> /=. done.
      move=> -> /=.
      rewrite (sumbool_of_boolET h256).
      by rewrite /of_estate /=.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /sem_sopn /=.
      rewrite get_gvar_neq //.
      rewrite (@get_gvar_eq _ tmp) /=; last by [].
      by rewrite /of_estate /= !zero_extend_u pword_of_wordE.
    apply: lsem_step.
    + rewrite /lsem1 /step.
      rewrite -addnS (find_instr_skip hlinear) /=.
      rewrite /eval_instr /= /of_estate /= zero_extend_u pword_of_wordE.
      by rewrite -addnS.
    apply: LSem_step.
    rewrite /lsem1 /step.
    rewrite (find_instr_skip hlinear) /=.
    rewrite /eval_instr /= /setpc /=.
    rewrite /of_estate /=.
    by rewrite -addnS.
  split=> //=.
  + do 7 rewrite get_var_neq //.
    rewrite get_var_eq /=. done.
  split=> //=.
  + move=> p. rewrite /between /zbetween !zify wsize8. Lia.lia.
  + do 9 (rewrite vmap_eq_except_set; last by apply /Sv_memP).
    done.
  + rewrite get_var_neq //.
    rewrite get_var_eq /=. done.
  + rewrite get_var_eq. done.
  + move: halign.
    rewrite /is_align !WArray.p_to_zE.
    by move=> /eqP /Z_mod_zero_opp_full /eqP.
  Lia.lia.
Qed.

Lemma fullP_large :
  get_gvar [::] s0.(evm) rsp = ok (Vword ptr) ->
  exists s2,
    lsem lp (of_estate s0 fn (size lc)) (of_estate s2 fn (size lc + size (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)))
    /\ state_rel s0 (write_c (x86_clear_stack_loop_large rspi lbl ws_align ws max_stk_size)) s2 0.
Proof.
  move=> hrsp.
  have [s1 [hsem1 hsr1]] := init_code_loopP' hrsp.
  have [s2 [hsem2 hsr2]] := loopP hsr1 ltac:(Lia.lia).
  exists s2; split=> //.
  by apply: (lsem_trans hsem1).
Qed.

End LARGE.


End Unrolled.

End CLEAR_STACK.
Opaque Uptr.

Lemma x86_hcsparams : h_clear_stack_params x86_csparams.
Proof.
  split.
  + move=> cs rsp lbl ws_align ws max_stk_size cmd.
    case: cs => /=.
    + move=> [<-].
      rewrite /x86_clear_stack_loop.
      + by case: ifP.
      move=> [<-].
      rewrite /x86_clear_stack_unrolled.
      case: ifP => _ /=.
      + by apply ziota_ind.
      by apply ziota_ind.

  move=> cs rsp lbl ws_align ws max_stk_size cmd.
  case: cs => /=.
  + move=> [<-] max_stk_pos halign hle lp fn lfd lc /negP hlabel hlfd hbody scs m vm ptr enough_stk ok_ptr hvalid.
   have hrsp': get_gvar [::] vm (mk_lvar rsp) = ok (Vword ptr).
   + done.
   have := fullP halign hle hlfd hlabel max_stk_pos hbody (s0 := Estate (spp:=mk_spp) scs m vm) enough_stk hvalid ok_ptr.
   move=> [s2 [hsem hsr]].
   exists (emem s2), (evm s2).
   split.
   + move: hsem; rewrite /of_estate /=.
     have /= <- := hsr.(sr_scs). done.
   + by apply hsr.(sr_vm).
   + by apply hsr.(sr_mem).
   split.
   + by apply hsr.(sr_disjoint).
   move=> p hb.
   apply hsr.(sr_clear).
   by rewrite Z.add_0_r.
  move=> [<-] max_stk_pos halign hle lp fn lfd lc /negP hlabel hlfd hbody scs m vm ptr enough_stk ok_ptr hvalid.
  admit.
Admitted.

(* ------------------------------------------------------------------------ *)
(* Flag combination hypotheses. *)

Lemma x86_cf_xsemP gd s e0 e1 e2 e3 cf v :
  let e := PappN (Ocombine_flags cf) [:: e0; e1; e2; e3 ] in
  let e' := cf_xsem enot eand eor expr.eeq e0 e1 e2 e3 cf in
  sem_pexpr gd s e = ok v
  -> sem_pexpr gd s e' = ok v.
Proof.
  rewrite /=.

  t_xrbindP=> vs0 v0 hv0 vs1 v1 hv1 vs2 v2 hv2 vs3 v3 hv3 ? ? ? ?;
    subst vs0 vs1 vs2 vs3.
  rewrite /sem_opN /=.
  t_xrbindP=> b b0 hb0 b1 hb1 b2 hb2 b3 hb3 hb ?; subst v.
  move: hb0 => /to_boolI ?; subst v0.
  move: hb1 => /to_boolI ?; subst v1.
  move: hb2 => /to_boolI ?; subst v2.
  move: hb3 => /to_boolI ?; subst v3.

  move: hb.
  rewrite /sem_combine_flags.
  rewrite /cf_xsem.

  case: cf_tbl => -[] [] [?] /=; subst b.
  all: by rewrite ?hv0 ?hv1 ?hv2 ?hv3.
Qed.

Definition x86_hpiparams : h_propagate_inline_params :=
  {|
    pip_cf_xsemP := x86_cf_xsemP;
  |}.

(* ------------------------------------------------------------------------ *)
(* Stack alloc hypotheses. *)

Section STACK_ALLOC.

  Variable (is_regx : var -> bool) (P' : sprog).
  Hypothesis P'_globs : P'.(p_globs) = [::].

  Lemma lea_ptrP s1 e i x tag ofs w s2 :
    (Let i' := sem_pexpr [::] s1 e in to_pointer i') = ok i
    -> write_lval [::] x (Vword (i + wrepr _ ofs)) s1 = ok s2
    -> psem.sem_i (pT := progStack) P' w s1 (lea_ptr x e tag ofs) s2.
  Proof.
    move=> he hx.
    constructor.
    rewrite /sem_sopn /= P'_globs /sem_sop2 /=.
    move: he; t_xrbindP=> _ -> /= -> /=.
    by rewrite !zero_extend_u hx.
  Qed.

End STACK_ALLOC.

Lemma x86_mov_ofsP (is_regx : var -> bool) (P' : sprog) s1 e i x tag ofs w vpk s2 ins :
  p_globs P' = [::]
  -> (Let i' := sem_pexpr [::] s1 e in to_pointer i') = ok i
  -> sap_mov_ofs (x86_saparams is_regx) x tag vpk e ofs = Some ins
  -> write_lval [::] x (Vword (i + wrepr Uptr ofs)) s1 = ok s2
  -> psem.sem_i (pT := progStack) P' w s1 ins s2.
Proof.
  move=> P'_globs he.
  rewrite /x86_saparams /= /x86_mov_ofs.
  case: (mk_mov vpk).
  - move=> [<-]. by apply lea_ptrP.
  case: eqP => [-> | _] [<-].
  + by rewrite wrepr0 GRing.addr0 -P'_globs; apply mov_wsP; rewrite // P'_globs.
  by apply lea_ptrP.
Qed.

Definition x86_hsaparams is_regx : h_stack_alloc_params (ap_sap x86_params is_regx) :=
  {|
    mov_ofsP := @x86_mov_ofsP is_regx;
  |}.

(* ------------------------------------------------------------------------ *)
(* Linearization hypotheses. *)

Section LINEARIZATION.

Context
  {call_conv : calling_convention}
  (lp : lprog)
  (s : estate)
  (sp_rsp : Ident.ident)
  (ii : instr_info)
  (fn : funname)
  (pc : nat).

Let vrsp : var := mk_ptr sp_rsp.
Let vrspi : var_i := VarI vrsp dummy_var_info.
Let vm := evm s.

Definition x86_spec_lip_allocate_stack_frame ts sz :
  let args := lip_allocate_stack_frame x86_liparams vrspi sz in
  let i := MkLI ii (Lopn args.1.1 args.1.2 args.2) in
  let ts' := pword_of_word (ts - wrepr Uptr sz) in
  let s' := with_vm s (vm.[vrsp <- ok ts'])%vmap in
  (vm.[vrsp])%vmap = ok (pword_of_word ts)
  -> eval_instr lp i (of_estate s fn pc)
     = ok (of_estate s' fn pc.+1).
Proof.
  move=> /= Hvm.
  rewrite /eval_instr /= /sem_sopn /=.
  rewrite /get_gvar /get_var /on_vu /=.
  rewrite Hvm /=.
  rewrite pword_of_wordE.
  by rewrite 3!zero_extend_u.
Qed.

Definition x86_spec_lip_free_stack_frame ts sz :
  let args := lip_free_stack_frame x86_liparams vrspi sz in
  let i := MkLI ii (Lopn args.1.1 args.1.2 args.2) in
  let ts' := pword_of_word (ts + wrepr Uptr sz) in
  let s' := with_vm s (vm.[vrsp <- ok ts'])%vmap in
  (vm.[vrsp])%vmap = ok (pword_of_word ts)
  -> eval_instr lp i (of_estate s fn pc)
    = ok (of_estate s' fn pc.+1).
Proof.
  move=> /= Hvm.
  rewrite /eval_instr /= /sem_sopn /=.
  rewrite /get_gvar /get_var /on_vu /=.
  rewrite Hvm /=.
  rewrite pword_of_wordE.
  by rewrite 3!zero_extend_u.
Qed.

Definition x86_spec_lip_ensure_rsp_alignment ws ts' :
  let al := align_word ws ts' in
  let args := lip_ensure_rsp_alignment x86_liparams vrspi ws in
  let i := MkLI ii (Lopn args.1.1 args.1.2 args.2) in
  get_var (evm s) vrsp = ok (Vword ts')
  -> wf_vm (evm s)
  -> exists vm',
      [/\ eval_instr lp i (of_estate s fn pc)
          = ok (of_estate (with_vm s vm') fn pc.+1)
        , vm' = (evm s).[vrsp <- ok (pword_of_word al)]%vmap
              [\one_varmap.vflags]
        , forall x,
            Sv.In x (one_varmap.vflags)
            -> ~ is_ok (vm'.[x]%vmap)
            -> (evm s).[x]%vmap = vm'.[x]%vmap
        & wf_vm vm'
      ].
Proof.
  move=> al /= Hvrsp.
  rewrite /eval_instr /= /sem_sopn /= /get_gvar /=.
  rewrite Hvrsp /=.
  rewrite !zero_extend_u pword_of_wordE /=.
  rewrite /with_vm /=.
  eexists; split; first by reflexivity.
  + move=> x hin. rewrite !(@Fv.setP _ _ vrsp).
    case: (vrsp =P x).
    + by move=> ?; subst x.
    move=> _.
    have hneq: forall (f : rflag), to_var f != x.
    + move=> f.
      apply/eqP => heq.
      apply /hin /sv_of_listP /mapP.
      exists f => //.
      rewrite /rflags /x86_decl.rflags.
      by rewrite (mem_cenum (cfinT := finC_rflag)).
    by rewrite !Fv.setP_neq.
  + move=> x /sv_of_listP /mapP [f _ ->].
    by case f;
      repeat (rewrite Fv.setP_eq || rewrite Fv.setP_neq //).
  by do! apply wf_vm_set.
Qed.

Definition x86_hlip_lassign
  (s1 s2 : estate) x e ws li ws' (w : word ws) (w' : word ws') :
  lassign x86_liparams x ws e = Some li
  -> sem_pexpr [::] s1 e = ok (Vword w')
  -> truncate_word ws w' = ok w
  -> write_lval [::] x (Vword w) s1 = ok s2
  -> eval_instr lp (MkLI ii li) (of_estate s1 fn pc)
     = ok (of_estate s2 fn pc.+1).
Proof.
  move=> /= hlassign Hsem_pexpr Htruncate_word Hwrite_lval.
  rewrite /eval_instr /= /sem_sopn /=.
  rewrite to_estate_of_estate.
  move: hlassign => [?]; subst li.
  rewrite /=.
  rewrite Hsem_pexpr /=.
  rewrite /exec_sopn /=.
  case: ws w Htruncate_word Hwrite_lval
    => /= ? Htruncate_word Hwrite_lval;
    rewrite Htruncate_word /=;
    rewrite Hwrite_lval /=;
    done.
Qed.

End LINEARIZATION.

Definition x86_hliparams {call_conv : calling_convention} : h_linearization_params (ap_lip x86_params) :=
  {|
    spec_lip_allocate_stack_frame := x86_spec_lip_allocate_stack_frame;
    spec_lip_free_stack_frame := x86_spec_lip_free_stack_frame;
    spec_lip_ensure_rsp_alignment := x86_spec_lip_ensure_rsp_alignment;
    hlip_lassign := x86_hlip_lassign;
  |}.

Lemma x86_ok_lip_tmp :
  exists r : reg_t, of_string (lip_tmp (ap_lip x86_params)) = Some r.
Proof.
  exists RAX.
  rewrite /=.
  change "RAX"%string with (to_string RAX).
  exact: to_stringK.
Qed.

(* ------------------------------------------------------------------------ *)
(* Lowering hypotheses. *)

Definition x86_hloparams : h_lowering_params (ap_lop x86_params).
Proof.
  split. exact: @lower_callP.
Defined.


(* ------------------------------------------------------------------------ *)
(* Assembly generation hypotheses. *)

(* FIXME: Is there a way of avoiding this import? *)
Import arch_sem.

Lemma not_condtP (c : cond_t) rf b :
  eval_cond rf c = ok b -> eval_cond rf (not_condt c) = ok (negb b).
Proof.
  case: c => /=.
  1,3,5,9,11: by case: (rf _) => //= ? [->].
  1,2,3,6,7: by case: (rf _) => //= ? [<-]; rewrite negbK.
  + by case: (rf CF) => //= ?; case: (rf _) => //= ? [<-]; rewrite negb_or.
  + by case: (rf CF) => //= ?; case: (rf _) => //= ? [<-]; rewrite -negb_or negbK.
  + by case: (rf SF) => //= ?; case: (rf _) => //= ? [<-]; rewrite negbK.
  + by case: (rf SF) => //= ?; case: (rf _) => //= ? [<-].
  + by case: (rf ZF) => //= ?; case: (rf SF) => //= ?; case: (rf _) => //= ? [<-]; rewrite negb_or negbK.
  by case: (rf ZF) => //= ?; case: (rf SF) => //= ?; case: (rf _) => //= ? [<-]; rewrite negb_and negbK.
Qed.

Lemma or_condtP ii e c1 c2 c rf b1 b2:
  or_condt ii e c1 c2 = ok c ->
  eval_cond rf c1 = ok b1 ->
  eval_cond rf c2 = ok b2 ->
  eval_cond rf c  = ok (b1 || b2).
Proof.
  case: c1 => //; case: c2 => //= -[<-] /=.
  + by case: (rf _) => // ? [->]; case: (rf _) => // ? [->].
  + by case: (rf _) => // ? [->]; case: (rf _) => // ? [->] /=; rewrite orbC.
  + by case: (rf ZF) => // ? [->]; case: (rf SF) => //= ?; case: (rf _) => //= ? [<-].
  by case: (rf SF) => //= ?; case: (rf _) => //= ? [<-]; case: (rf _) => //= ? [->]; rewrite orbC.
Qed.

Lemma and_condtP ii e c1 c2 c rf b1 b2:
  and_condt ii e c1 c2 = ok c ->
  eval_cond rf c1 = ok b1 ->
  eval_cond rf c2 = ok b2 ->
  eval_cond rf c  = ok (b1 && b2).
Proof.
  case: c1 => //; case: c2 => //= -[<-] /=.
  + by case: (rf _) => // ? [<-]; case: (rf _) => // ? [<-].
  + by case: (rf _) => // ? [<-]; case: (rf _) => // ? [<-] /=; rewrite andbC.
  + by case: (rf ZF) => // ? [<-]; case: (rf SF) => //= ?; case: (rf _) => //= ? [<-].
  by case: (rf SF) => //= ?; case: (rf _) => //= ? [<-]; case: (rf _) => //= ? [->]; rewrite andbC.
Qed.

Lemma of_var_e_boolP ii x f :
  of_var_e_bool ii x = ok f ->
  of_var_e ii x = ok f.
Proof. by rewrite /of_var_e_bool /of_var_e; case: of_var. Qed.

Lemma eval_assemble_cond ii m rf e c v:
  eqflags m rf
  -> agp_assemble_cond x86_agparams ii e = ok c
  -> sem_pexpr [::] m e = ok v
  -> exists2 v',
       value_of_bool (eval_cond (get_rf rf) c) = ok v' & value_uincl v v'.
Proof.
  rewrite /x86_agparams /eval_cond /get_rf /=.
  move=> eqv; elim: e c v => //.
  + move=> x c v /=; t_xrbindP=> r /of_var_e_boolP ok_r ok_ct ok_v.
    have := gxgetflag_ex eqv ok_r ok_v.
    case: {ok_r ok_v} r ok_ct => // -[<-] {c} /= h;
      eexists;
      eauto;
      by case: (rf _).
  + case => //= e hrec; t_xrbindP => c v ce hce <- ve hve.
    rewrite /sem_sop1 /=; t_xrbindP => b hb <-.
    have := hrec _ _ hce hve.
    move=> /(value_of_bool_uincl hb).
    move=> -/not_condtP /=.
    move=> ->.
    by exists (~~b).
  case => //=.
  + move=> e1 _ e2 _ c v.
    case: e1 => //= x1; case: e2 => //= x2; t_xrbindP => f1 /of_var_e_boolP ok_f1 f2 /of_var_e_boolP ok_f2.
    case: ifP => // /orP hor [<-] v1 /(gxgetflag eqv ok_f1) hv1 v2 /(gxgetflag eqv ok_f2) hv2.
    move=> /sem_sop2I /= [b1 [b2 [b3 [hb1 hb2 [<-] ->]]]].
    move: (hv1 _ hb1) (hv2 _ hb2) => hfb1 hfb2.
    exists (b1 == b2); last done.
    by case: hor => /andP [] /eqP ? /eqP ?; subst f1 f2; rewrite hfb1 hfb2 //= eq_sym.
  + move=> e1 hrec1 e2 hrec2 c v; t_xrbindP => c1 hc1 c2 hc2 hand v1 hv1 v2 hv2.
    move=> /sem_sop2I /= [b1 [b2 [b3 [hb1 hb2 [<-] ->]]]].
    have /(value_of_bool_uincl hb1) hec1 := hrec1 _ _ hc1 hv1.
    have /(value_of_bool_uincl hb2) hec2 := hrec2 _ _ hc2 hv2.
    have /= -> := and_condtP hand hec1 hec2.
    by exists (b1 && b2).
  move=> e1 hrec1 e2 hrec2 c v; t_xrbindP => c1 hc1 c2 hc2 hor v1 hv1 v2 hv2.
  move=> /sem_sop2I /= [b1 [b2 [b3 [hb1 hb2 [<-] ->]]]].
  have /(value_of_bool_uincl hb1) hec1 := hrec1 _ _ hc1 hv1.
  have /(value_of_bool_uincl hb2) hec2 := hrec2 _ _ hc2 hv2.
  have /= -> := or_condtP hor hec1 hec2.
  by exists (b1 || b2).
Qed.

Lemma assemble_extra_op rip ii op lvs args op' lvs' args' op'' asm_args m m' s :
  sem_sopn [::] (Oasm (ExtOp op)) m lvs args = ok m'
  -> to_asm ii op lvs args = ok (op', lvs', args')
  -> assemble_asm_op x86_agparams rip ii op' lvs' args'
     = ok (op'', asm_args)
  -> lom_eqv rip m s
  -> exists2 s', eval_op op'' asm_args s = ok s' & lom_eqv rip m' s'.
Proof.
  rewrite /x86_agparams /=.
  case: op.
  + move=> sz; rewrite /sem_sopn /exec_sopn /sopn_sem /=.
    rewrite /Oset0_instr; case: ifP => /= hsz64.
    + t_xrbindP => ? []// ?? [<-] /= <-.
      move=> hw x hx <- <- <-; rewrite /assemble_asm_op.
      t_xrbindP => asm_args' _ hc.
      case hci: enforce_imm_i_args_kinds =>
        {asm_args} [asm_args|//] _ [<-] /andP [hca hcd] <- <-.
      have {hci} hidc := filter_i_args_kinds_no_imm_correct (enforce_imm_i_args_kinds_correct hci).
      move: hca; rewrite /check_sopn_args /= => /and3P [].
      rewrite /check_sopn_arg /=.
      case: asm_args hidc hcd => //= a0 [ // | ] a1 [] //= hidc hcd;
       last by rewrite /check_args_kinds /= !andbF.
      case ok_y: xreg_of_var => [y|//]; move /xreg_of_varI in ok_y.
      rewrite !andbT /compat_imm.
      case: y ok_y => // r xr; rewrite !orbF => /eqP ? /eqP ? _; subst a0 a1; only 2-3: by [].
      rewrite /eval_op /exec_instr_op /= /eval_instr_op /=.
      rewrite /truncate_word /x86_XOR /check_size_8_64 hsz64 /= wxor_xx.
      set id := instr_desc_op (XOR sz) => hlo.
      rewrite /SF_of_word msb0.
      by apply: (@compile_lvals _ _ _ _ _ _ _ _ _ _ _
             rip ii m lvs m' s [:: Reg r; Reg r]
             id.(id_out) id.(id_tout)
             (let vf := Some false in let: vt := Some true in (::vf, vf, vf, vt, vt & (0%R: word sz)))
             (reg_msb_flag sz) (refl_equal _) hw hlo hcd id.(id_check_dest)).
    t_xrbindP => ? []// ?? [<-] /= <-.
    move=> hw x hx <- <- <-; rewrite /assemble_asm_op.
    t_xrbindP => asm_args' _ hc.
    case hci: enforce_imm_i_args_kinds =>
      {asm_args} [asm_args|//] _ [<-] /andP [hca hcd] <- <-.
    have {hci} hidc := filter_i_args_kinds_no_imm_correct (enforce_imm_i_args_kinds_correct hci).
    move: hca; rewrite /check_sopn_args /= => /and3P [].
    rewrite /check_sopn_arg /=.
    case: asm_args hidc hcd => //= a0 [// | ] a1 [] //= a2 [] //=;
      last by rewrite /check_args_kinds /= !andbF.
    rewrite orbF => hidc hcd.
    case ok_y: xreg_of_var => [y|//]; move /xreg_of_varI in ok_y.
    rewrite !andbT /compat_imm.
    case: y ok_y => // r xr; rewrite !orbF => /eqP ? /eqP ? _; subst a1 a2.
    1-2: by move: hidc; rewrite /check_args_kinds /= andbF.
    rewrite /eval_op /exec_instr_op /= /eval_instr_op /=.
    rewrite /truncate_word /x86_VPXOR hidc /= /x86_u128_binop /check_size_128_256 wsize_ge_U256.
    have -> /= : (U128 ≤ sz)%CMP by case: (sz) hsz64.
    rewrite wxor_xx; set id := instr_desc_op (VPXOR sz) => hlo.
    by apply: (@compile_lvals _ _ _ _ _ _ _ _ _ _ _ 
               rip ii m lvs m' s [:: a0; XReg r; XReg r]
               id.(id_out) id.(id_tout)
               (0%R: word sz)
               (reg_msb_flag sz) (refl_equal _) hw hlo hcd id.(id_check_dest)).
  + t_xrbindP.
    case: args => // h [] // [] // x [] //=.
    rewrite /sem_sopn /exec_sopn /sopn_sem /=.
    t_xrbindP => ?? vh hvh ? vl hvl <- <- /= vd.
    t_xrbindP => wh hwh wl hwl <- <- /= hwr <- <- <-.
    rewrite /assemble_asm_op.

    t_xrbindP => asm_args' haux hc'.
    case hci: enforce_imm_i_args_kinds =>
      {asm_args} [asm_args|//] _ [<-] /andP [hca hcd] <- <- hlow.
    have {hci} hch := filter_i_args_kinds_no_imm_correct (enforce_imm_i_args_kinds_correct hci).
    have [s' hwm hlow'] :=
      compile_lvals (asm_e:=x86_extra)
       (id_out := [:: E 0]) (id_tout := [:: sword256]) MSB_CLEAR refl_equal hwr hlow hcd refl_equal.
    exists s'; last done.
    move: hca; rewrite /check_sopn_args /= => /and4P [] hE1 hE2 hE3 _.
Opaque eval_arg_in_v check_i_args_kinds.
    rewrite /eval_op /exec_instr_op /= /eval_instr_op /= hch.
    have [vh' -> /= hvh'] :=
      check_sopn_arg_sem_eval eval_assemble_cond hlow hE2 hvh hwh.
    have [v1 /= -> hv1 /=] :=
      check_sopn_arg_sem_eval eval_assemble_cond hlow hE3 refl_equal (truncate_word_u _).
Transparent eval_arg_in_v check_i_args_kinds.
    move: hE1; rewrite /check_sopn_arg /=.
    case: oseq.onth => // a.
    case: x hvl haux => x [] // hvl haux.
    case heq: xreg_of_var => [ a' | //] /andP[] hc _.
    have := xreg_of_varI heq => {heq}.
    case: a' hc => //= [ r | rx | xmm].
    + rewrite /compat_imm; case:a => //= r' /orP [/eqP [?]|//] hr; subst r'.
      have heq := of_varI hr.
      move: hvl.
      rewrite /get_gvar /= -heq => hvl.
      case: hlow => _ _ _ _ /(_ _ _ hvl) hu _ _ _.
      move: hwl hu; rewrite /to_word.
      case: (vl) => // [ ws w /=| []//].
      rewrite /truncate_word /word_uincl.
      case: ifP => // h1 _ /andP [] h2.
      by have := cmp_le_trans h1 h2.
    + rewrite /compat_imm; case:a => //= r' /orP [/eqP [?]|//] hr; subst r'.
      have heq := of_varI hr.
      move: hvl.
      rewrite /get_gvar /= -heq => hvl.
      case: hlow => _ _ _ _ _ /(_ _ _ hvl) hu _ _.
      move: hwl hu; rewrite /to_word.
      case: (vl) => // [ ws w /=| []//].
      rewrite /truncate_word /word_uincl.
      case: ifP => // h1 _ /andP [] h2.
      by have := cmp_le_trans h1 h2.
    rewrite /compat_imm; case:a => //= xmm' /orP [ /eqP[?]| //] hxmm;subst xmm'.
    rewrite hvh' hv1 /= -hwm /=; do 3! f_equal.
    have := xxgetreg_ex hlow hxmm hvl.
    rewrite zero_extend_u /winserti128 => hu.
    have -> : (lsb (wrepr U8 (wunsigned 1))) by done.
    do 2! f_equal; rewrite /split_vec /=.
    move: hwl hu; rewrite /to_word.
    case: (vl) => // [ws wl' /= | []//].
    rewrite /truncate_word /word_uincl mul0n.
    case: ifP => // hle.
    rewrite (@subword0 U128 U256) // => -[] <- /andP [] _ /eqP ->.
    by rewrite zero_extend_idem.
  case: lvs => // -[] // x [] //.
  rewrite /sem_sopn /exec_sopn /sopn_sem /=.
  case: args => //= a args.
  t_xrbindP => vs1 vs2 va hva vs3 h <- /=.
  case: args h => /=; t_xrbindP; last by move=> *; subst.
  move => <- ? wa htwa [<-] <-; t_xrbindP => m1 hwx ? <- <- <-;subst m1.
  rewrite /assemble_asm_op.
  t_xrbindP => asm_args' _ hc.
  case hci: enforce_imm_i_args_kinds =>
    {asm_args} [asm_args|//] _ [<-] /andP [hca hcd] <- <- hlo.
  have {hci} hidc := filter_i_args_kinds_no_imm_correct (enforce_imm_i_args_kinds_correct hci).
  case: asm_args hidc hcd hca => // a0 [] // a1 []// hidc hcd;
    last by rewrite /check_args_kinds /= !andbF.
  rewrite /check_sopn_args /= andbT => hca1.
  rewrite /eval_op /exec_instr_op /= /eval_instr_op /=.
  rewrite /= in hidc;rewrite hidc.
  have [v' /= -> /= -> /=] :=
    check_sopn_arg_sem_eval eval_assemble_cond hlo hca1 hva htwa.
  move: hcd; rewrite /check_sopn_dests /= /check_sopn_dest /= => /andP -[].
  case ok_y: xreg_of_var => [y|//]; move /xreg_of_varI in ok_y.
  rewrite andbT => /eqP ? _; subst a0.
  case: y hidc hca1 ok_y => // r hidc hca1 /of_varI xr.
  rewrite /mem_write_vals.
  eexists; first reflexivity.
  case: hlo => h0 h1 hrip hd h2 h2x h3 h4.
  move: hwx; rewrite /write_var /set_var.
  rewrite -xr => -[<-]{m'}.
  constructor => //=.
  + by rewrite /get_var Fv.setP_neq //; apply /eqP;case: hd.
  + move=> r' v''; rewrite /get_var /on_vu /= /RegMap.set ffunE.
    case: eqP => [-> | hne].
    + by rewrite Fv.setP_eq /reg_msb_flag /= word_extend_CLEAR zero_extend_u => -[<-].
    rewrite Fv.setP_neq; last by apply /eqP => h; apply hne; apply inj_to_var.
    by apply h2.
  + move=> r' v''; rewrite /get_var /on_vu /= Fv.setP_neq; first by apply h2x.
    by apply/eqP/to_var_reg_neq_regx.
  + move=> r' v''; rewrite /get_var /on_vu /=.
    by rewrite Fv.setP_neq //; apply h3.
  move=> f v''; rewrite /get_var /on_vu /=.
  by rewrite Fv.setP_neq //; apply h4.
Qed.

Definition x86_hagparams : h_asm_gen_params (ap_agp x86_params) :=
  {|
    hagp_eval_assemble_cond := eval_assemble_cond;
    hagp_assemble_extra_op := assemble_extra_op;
  |}.

(* ------------------------------------------------------------------------ *)
(* Shared hypotheses. *)

Definition x86_is_move_opP op vx v :
  ap_is_move_op x86_params op
  -> exec_sopn (Oasm op) [:: vx ] = ok v
  -> List.Forall2 value_uincl v [:: vx ].
Proof.
  by case: op => // -[] [] // [] //= ws _;
    rewrite /exec_sopn /=;
    t_xrbindP=> w ? /to_wordI' [ws' [wx [hle -> ->]]];
    rewrite /sopn_sem /=;
    match goal with
    | |- ?f (zero_extend _ _) = _ -> _ => rewrite /f
    end;
    t_xrbindP=> _ <- <-;
    (constructor; last by constructor);
    apply word_uincl_zero_ext.
Qed.


(* ------------------------------------------------------------------------ *)

Definition x86_h_params {call_conv : calling_convention} : h_architecture_params x86_params :=
  {|
    hap_hpip := x86_hpiparams;
    hap_hsap := x86_hsaparams;
    hap_hlip := x86_hliparams;
    ok_lip_tmp := x86_ok_lip_tmp;
    hap_hlop := x86_hloparams;
    hap_hagp := x86_hagparams;
    hap_is_move_opP := x86_is_move_opP;
  |}.

End Section.

(* ** License
 * -----------------------------------------------------------------------
 * Copyright 2016--2017 IMDEA Software Institute
 * Copyright 2016--2017 Inria
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * ----------------------------------------------------------------------- *)

(* ** Imports and settings *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import psem compiler_util.
Require Export dead_code.
Import Utf8.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope vmap.
Local Open Scope seq_scope.

Section Section.

Context {T:eqType} {pT:progT T} {sCP: semCallParams}.

Section PROOF.

  Hypothesis wf_init: wf_init sCP.

  Variables (onfun : funname -> option (seq bool)) (p p' : prog) (ev:extra_val_t).
  Notation gd := (p_globs p).

  Hypothesis dead_code_ok : dead_code_prog_tokeep onfun p = ok p'.

  Lemma eq_globs : gd = p_globs p'.
  Proof. by move: dead_code_ok; rewrite /dead_code_prog_tokeep; t_xrbindP => ? _ <-. Qed.
 
  Lemma eq_p_extra : p_extra p = p_extra p'.
  Proof. by move: dead_code_ok; rewrite /dead_code_prog_tokeep; t_xrbindP => ? _ <-. Qed.

  Let Pi_r s (i:instr_r) s' :=
    forall ii s2,
      match dead_code_i onfun (MkI ii i) s2 with
      | Ok (s1, c') =>
        wf_vm s.(evm) ->
        forall vm1', s.(evm) <=[s1] vm1' ->
          exists vm2', s'.(evm) <=[s2] vm2' /\
          sem p' ev (with_vm s vm1') c' (with_vm s' vm2')
      | _ => True
      end.

  Let Pi s (i:instr) s' :=
    forall s2,
      match dead_code_i onfun i s2 with
      | Ok (s1, c') =>
        wf_vm s.(evm) ->
        forall vm1', s.(evm) <=[s1] vm1' ->
          exists vm2', s'.(evm) <=[s2] vm2' /\
          sem p' ev (with_vm s vm1') c' (with_vm s' vm2')
      | _ => True
      end.

  Let Pc s (c:cmd) s' :=
    forall s2,
      match dead_code_c (dead_code_i onfun) c s2 with
      | Ok (s1, c') =>
        wf_vm s.(evm) ->
        forall vm1', s.(evm) <=[s1] vm1' ->
        exists vm2', s'.(evm) <=[s2] vm2' /\
          sem p' ev (with_vm s vm1') c' (with_vm s' vm2')
      | _ => True
      end.

  Let Pfor (i:var_i) vs s c s' :=
    forall s2,
      match dead_code_c (dead_code_i onfun) c s2 with
      | Ok (s1, c') =>
        Sv.Subset (Sv.union (read_rv (Lvar i)) (Sv.diff s1 (vrv (Lvar i)))) s2 ->
        wf_vm s.(evm) ->
        forall vm1', s.(evm) <=[s2] vm1' ->
        exists vm2', s'.(evm) <=[s2] vm2' /\
          sem_for p' ev i vs (with_vm s vm1') c' (with_vm s' vm2')
      | _ => True
      end.

  Let Pfun m1 fn vargs m2 vres :=
    sem_call p' ev m1 fn vargs m2 (fn_keep_only onfun fn vres).

  Local Lemma Hskip : sem_Ind_nil Pc.
  Proof. by move=> s1 s2 Hwf vm' Hvm; exists vm'; split=> //; constructor. Qed.

  (* FIXME: MOVE THIS *)
  Lemma wf_sem_I p0 ev0 s1 i s2 :
    sem_I p0 ev0 s1 i s2 -> wf_vm (evm s1) -> wf_vm (evm s2).
  Proof. by move=> H;have := sem_seq1 H; apply: wf_sem. Qed.

  Local Lemma Hcons : sem_Ind_cons p ev Pc Pi.
  Proof.
    move=> s1 s2 s3 i c H Hi H' Hc sv3 /=.
    have := Hc sv3.
    case: (dead_code_c (dead_code_i onfun) c sv3)=> [[sv2 c']|//] Hc' /=.
    have := Hi sv2.
    case: (dead_code_i onfun i sv2)=> [[sv1 i']|] //= Hi' Hwf vm1' /(Hi' Hwf).
    have Hwf2 := wf_sem_I H Hwf.
    move=> [vm2' [Heq2 Hsi']];case: (Hc' Hwf2 _ Heq2) => [vm3' [Heq3 Hsc']].
    exists vm3';split=> //.
    by apply: sem_app Hsi' Hsc'.
  Qed.

  Local Lemma HmkI : sem_Ind_mkI p ev Pi_r Pi.
  Proof. move=> ii i s1 s2 _ Hi; exact: Hi. Qed.

  Lemma check_nop_spec (r:lval) ty (e:pexpr): check_nop r ty e ->
    exists x i1 i2, [/\ r = (Lvar (VarI x i1)), e = (Plvar(VarI x i2)) & ty = vtype x] .
  Proof.
    case: r e => //= -[x1 i1] [] //= [[x2 i2] k2] /andP [] /andP [] /eqP /= -> /eqP <- /eqP ->.
    by exists x1, i1, i2. 
  Qed.

  Local Lemma Hassgn_aux ii s1 s2 v v' x tag ty e s:
    sem_pexpr gd s1  e = ok v ->
    truncate_val ty v = ok v' ->
    write_lval gd x v' s1 = ok s2 ->
    wf_vm (evm s1) →
    ∀ vm1' : vmap,
      (evm s1) <=[read_rv_rec (read_e_rec (Sv.diff s (write_i (Cassgn x tag ty e))) e) x]  vm1' →
      ∃ vm2' : vmap, (evm s2) <=[s]  vm2'
        ∧ sem p' ev (with_vm s1 vm1') [:: MkI ii (Cassgn x tag ty e)] (with_vm s2 vm2').
  Proof.
    move=> Hv Hv' Hw Hwf vm1' Hvm.
    rewrite write_i_assgn in Hvm.
    move: Hvm; rewrite read_rvE read_eE=> Hvm.
    have Hmem : s1 = {|emem := emem s1; evm := evm s1|}. by case: (s1).
    rewrite Hmem in Hv.
    have /sem_pexpr_uincl_on'  -/(_ _ _ _ Hv): (evm s1) <=[read_e e] vm1'.
    + by apply: vmap_uincl_onI Hvm;SvD.fsetdec.
    move=> [v''] Hv'' Hveq.
    have Huincl := truncate_value_uincl Hv'.
    have [v''' Ht Hv''']:= value_uincl_truncate Hveq Hv'.
    have [| vm2' Hvm2 Hw2]:= write_lval_uincl_on _ Hv''' Hw Hvm; first by SvD.fsetdec.
    exists vm2'; split; first by apply: vmap_uincl_onI Hvm2; SvD.fsetdec.
    apply sem_seq1; constructor. apply Eassgn with v'' v''';rewrite -?eq_globs.
    rewrite /with_vm /=. apply Hv''. apply Ht. apply Hw2.
  Qed.

(* move to psem *)
Lemma vrvP_var_uincl (x:var_i) v s1 s2 :
  write_var x v s1 = ok s2 ->
  s1.(evm) <=[Sv.add x Sv.empty] s2.(evm). 
Proof.
  rewrite /write_var;t_xrbindP => vm. Search _ set_var.
  apply: set_varP=> [t | _]=> H <- <- z Hz;rewrite Fv.setP_neq //; apply /eqP.
Admitted.

(* move to psem *)
Lemma disjoint_unicl_on gd s r s1 s2 v:
  disjoint s (vrv r) ->
  write_lval gd r v s1 = ok s2 ->
  s1.(evm) <=[s] s2.(evm).
Proof.
  (*move=> Hd. Search _ write_lval.  /vrvP H z Hnin. apply H.
  move:Hd;rewrite /disjoint /is_true Sv.is_empty_spec;SvD.fsetdec.*)
Admitted.

Lemma disjoint_uincl_ons gd s r s1 s2 v:
  disjoint s (vrvs r) ->
  write_lvals gd s1 r v = ok s2 ->
  s1.(evm) <=[s] s2.(evm).
Proof.
  (*move=> Hd /vrvsP H z Hnin;apply H.
  move:Hd;rewrite /disjoint /is_true Sv.is_empty_spec;SvD.fsetdec.*)
Admitted.

  Local Lemma Hwrite_disj s1 s2 s x v:
    write_lval gd x v s1 = ok s2 ->
    disjoint s (vrv x) ->
    ~~ lv_write_mem x ->
    evm s1 <=[s] evm s2 /\  emem s1 = emem s2.
  Proof.
    move=> Hw Hdisj Hwmem; rewrite (lv_write_memP Hwmem Hw); split => //.
    by apply: disjoint_unicl_on Hdisj Hw.
  Qed.

  Local Lemma Hwrites_disj s1 s2 s x v:
    write_lvals gd s1 x v = ok s2 ->
    disjoint s (vrvs x) ->
    ~~ has lv_write_mem x ->
    evm s1 <=[s] evm s2 /\ emem s1 = emem s2.
  Proof.
    elim: x v s1 => [ | x xs Hrec] [ | v vs] //= s1.
    + by move=> [] <- H _; split=> //.
    t_xrbindP => s3 Hw Hws;rewrite /vrvs /= vrvs_recE -/vrv negb_or.
    move=> Hdisj /andP [] Hnw Hnh.
    have /(_ s) [] := Hwrite_disj Hw _ Hnw.
    + by move: Hdisj;rewrite /disjoint /is_true !Sv.is_empty_spec;SvD.fsetdec.
    move=> Hvm ->;have [] := (Hrec _ _ Hws _ Hnh).
    + by move: Hdisj;rewrite /disjoint /is_true !Sv.is_empty_spec;SvD.fsetdec.
    move=> H1 H2; split=> //; apply : vmap_uincl_onT Hvm H1.
  Qed.

  Local Lemma Hassgn : sem_Ind_assgn p Pi_r.
  Proof.
   move => [m1 vm1] [m2 vm2] x tag ty e v v' Hv htr Hw ii s /=.
    case: ifPn=> _ /=; last by apply: Hassgn_aux Hv htr Hw.
    case: ifPn=> /= [ | _].
    + rewrite write_i_assgn => /andP [Hdisj Hwmem] Hwf vm1' Hvm.
      have /= := Hwrite_disj Hw Hdisj Hwmem. move=> [] Hvm1 <-.
      rewrite /with_vm /=; exists vm1' => /=;split; last by constructor.
      admit.
      (*by apply:eq_onT Hvm;apply eq_onS.*)
    (*case: ifPn=> Hnop /=;last by apply: Hassgn_aux Hv htr Hw.
    move=> Hwf vm1' Hvm.
    have [-> Hs] : m1 = m2 /\ vm2 =v vm1.
    + move: (check_nop_spec Hnop)=> {Hnop} [x0 [i1 [i2 [Hx He Hty]]]];subst x e.
      case: x0 Hty Hv Hw => ? xn0 /= <- Hv Hw.
      have ?: v' = v.
      + by apply: on_vuP Hv => //= ???;subst; apply: truncate_pto_val htr.
      subst.
      move: Hw;rewrite /= /write_var/set_var /=.
      apply: on_vuP Hv => //= t Hx0 ?;subst v.
      rewrite pof_val_pto_val /= => -[<- <-]; split => // z.
      by case: ({|vtype := ty;vname := xn0|} =P z) => [<-|/eqP Hne];rewrite ?Fv.setP_eq ?Fv.setP_neq.
    eexists; split.
    + apply: vmap_uincl_onT=> //.
    + apply: eq_onT _ Hvm => //.
    apply: Eskip.
  Qed.*)
  Admitted.

  Lemma check_nop_opn_spec (xs:lvals) (o:sopn) (es:pexprs): check_nop_opn xs o es ->
    exists x i1 sz i2,

      [/\ xs = [:: Lvar (VarI (Var (sword sz) x) i1)], 
          (o = Ox86 (MOV sz) \/ o = Ox86 (VMOVDQU sz)) &
          es = [:: Plvar (VarI (Var (sword sz) x) i2)] ].
  Proof.
    case: xs o es => // rv [] // [] // [] // sz [] // e [] //= /check_nop_spec [x [i1 [i2 []]]] -> -> /=;
      case: x => ty xn /= <-;exists xn, i1, sz, i2; split => //; auto.
  Qed.

  Lemma set_get_word vm1 vm2 sz xn v:
    let x := {| vtype := sword sz; vname := xn |} in
    get_var vm1 x = ok v ->
    set_var vm1 x v = ok vm2 ->
    vm1 =v vm2.
  Proof.
    rewrite /get_var /set_var.
    apply: on_vuP=> //= t Hr <- /= [<-].
    have -> /= := sumbool_of_boolET (pw_proof t).
    move => z.
    set x0 := {| vtype := _; vname := xn |}.
    case: (x0 =P z) => [<-|/eqP Hne];rewrite ?Fv.setP_eq ?Fv.setP_neq //.
    by rewrite -/x0 Hr;case: (t).
  Qed.

  Lemma get_var_word sz w x vm:
    get_var vm x = ok (@Vword sz w) ->
    exists sz', vtype x = sword sz' /\ (sz <= sz')%CMP.
  Proof.
    move: x=> [vt vn]; rewrite /=.
    rewrite /get_var /on_vu.
    case Hv: vm.[_]=> /= [v|[] //] [] H {Hv}.
    case: vt v H => //= sz' v /Vword_inj [e ];subst => /= ?.
    by exists sz';split=> //;apply pw_proof.
  Qed.
 
  Local Lemma Hopn_aux s0 ii xs t o es v vs s1 s2 :
    sem_pexprs gd s1 es = ok vs ->
    exec_sopn o vs = ok v ->
    write_lvals gd s1 xs v = ok s2 ->
    wf_vm (evm s1) → ∀ vm1' : vmap,
    evm s1 <=[read_es_rec (read_rvs_rec (Sv.diff s0 (vrvs xs)) xs) es]  vm1' →
    ∃ vm2' : vmap, evm s2 =[s0]  vm2' ∧
       sem p' ev (with_vm s1 vm1') [:: MkI ii (Copn xs t o es)] (with_vm s2 vm2').
  Proof.
    (*move=> /= Hexpr Hopn Hw Hwf vm1' Hvm.
    move: Hvm; rewrite read_esE read_rvsE=> Hvm.
    have [|vm2 [Hvm2 Hvm2']] := write_lvals_unicl_on _ Hw Hvm; first by SvD.fsetdec.
    exists vm2; split.
    + by apply: eq_onI Hvm2; SvD.fsetdec.
    econstructor;last by constructor.
    constructor; constructor; rewrite -eq_globs.
    rewrite /sem_sopn -(@read_es_eq_on _ _ Sv.empty).
    + by rewrite Hexpr /= Hopn.
    by rewrite read_esE; apply: eq_onI Hvm;SvD.fsetdec.*)
  Admitted.

  Local Lemma Hopn : sem_Ind_opn p Pi_r.
  Proof.
    (*move => s1 s2 t o xs es.
    apply: rbindP=> v; apply: rbindP=> x0 Hexpr Hopn Hw.
    rewrite /Pi_r /= => ii s0.
    case: ifPn => _ /=; last by apply: Hopn_aux Hexpr Hopn Hw.
    case:ifPn => [ | _] /=.
    + move=> /andP [Hdisj Hnh] Hwf vm1' Heq;exists vm1'.
      case: s1 s2 Hw Hexpr Hwf Heq => m1 vm1 [m2 vm2] Hw _ Hwf /= Heq.
      have [/= ? ->]:= Hwrites_disj Hw Hdisj Hnh; split; last by constructor.
      by apply: eq_onT Heq;apply eq_onS.
    case:ifPn => [ | _ /=]; last by apply: Hopn_aux Hexpr Hopn Hw.
    move=> /check_nop_opn_spec [x [i1 [sz [i2 [? ho ?]]]]]; subst xs es=> /= Hwf vm1' Hvm.
    rewrite (surj_estate s1) (surj_estate s2) /with_vm /=.
    have [ -> Hs ]: emem s1 = emem s2 ∧ evm s1 =v evm s2;
      last by eexists; split; last exact: Eskip; apply: eq_onT _ Hvm.
    case: x0 Hexpr Hopn => [ | vx] /=; first by t_xrbindP.
    case; t_xrbindP => // vx' hgetx ? hs; subst vx'.
    have ? : v = [::vx].
    + case: ho hs => ->; rewrite /exec_sopn /=; t_xrbindP => v1 w1 /to_wordI [sz' [w' [hsz' ??]]]; subst vx w1.
      + rewrite /sopn_sem /= /x86_MOV; t_xrbindP => ? /assertP ha ??; subst v1 v.
        have [sz'' /= [[? hle']]]:= get_var_word hgetx;subst sz''.
        have ? := cmp_le_antisym hsz' hle'; subst sz'.
        by rewrite zero_extend_u.
      rewrite /sopn_sem /= /x86_VMOVDQU; t_xrbindP => ? /assertP ha ??; subst v1 v.
      have [sz'' /= [[? hle']]]:= get_var_word hgetx;subst sz''.
      have ? := cmp_le_antisym hsz' hle'; subst sz'.
      by rewrite zero_extend_u.
    subst v; move: Hw; rewrite /= /write_var; t_xrbindP => s2' vm2 hw ??; subst s2 s2'.
    case: s1 Hwf Hvm hgetx hw => mem1 vm1 /= Hwf Hvm hgetx hw.
    by have := set_get_word hgetx hw. *)
  Admitted.

  Local Lemma Hif_true : sem_Ind_if_true p ev Pc Pi_r.
  Proof.
    move=> s1 s2 e c1 c2 Hval Hp Hc ii sv0 /=.
    case Heq: (dead_code_c (dead_code_i onfun) c1 sv0)=> [[sv1 sc1] /=|//].
    case: (dead_code_c (dead_code_i onfun) c2 sv0)=> [[sv2 sc2] /=|//] Hwf vm1' Hvm.
    move: (Hc sv0); rewrite Heq => /(_ Hwf vm1') [|vm2' [Hvm2' Hvm2'1]].
    move: Hvm; rewrite read_eE=> Hvm.
    apply: vmap_uincl_onI Hvm;SvD.fsetdec.
    have Hmem : s1 = {|emem := emem s1; evm := evm s1|}. by case: (s1).
    rewrite Hmem in Hval.
    have := sem_pexpr_uincl_on' Hvm Hval.
    move=> [v] Hval' Hv.
    exists vm2'; split=> //.
    econstructor; constructor.
    constructor=> //; rewrite -?eq_globs.
    rewrite /value_uincl in Hv. case: v Hv Hval'=> //=.
    by move=> b -> Hval'. 
  Qed.

  Local Lemma Hif_false : sem_Ind_if_false p ev Pc Pi_r.
  Proof.
    move=> s1 s2 e c1 c2 Hval Hp Hc ii sv0 /=.
    case: (dead_code_c (dead_code_i onfun) c1 sv0)=> [[sv1 sc1] /=|//].
    case Heq: (dead_code_c (dead_code_i onfun) c2 sv0)=> [[sv2 sc2] /=|//] Hwf vm1' Hvm.
    move: (Hc sv0).
    rewrite Heq.
    move=> /(_ Hwf vm1') [|vm2' [Hvm2' Hvm2'1]].
    move: Hvm; rewrite read_eE=> Hvm.
    apply: vmap_uincl_onI Hvm;SvD.fsetdec.
    have Hmem : s1 = {|emem := emem s1; evm := evm s1|}. by case: (s1).
    rewrite Hmem in Hval.
    have := sem_pexpr_uincl_on' Hvm Hval.
    move=> [v] Hval' Hv.
    exists vm2'; split=> //.
    econstructor; constructor.
    apply: Eif_false=> //; rewrite -?eq_globs.
    rewrite /value_uincl in Hv. case: v Hv Hval'=> //=.
    by move=> b -> Hval'. 
  Qed.

  Lemma wloopP f ii n s sic:
    wloop f ii n s = ok sic →
    ∃ si s', Sv.Subset s si ∧ f si = ok (s', sic) ∧ Sv.Subset s' si.
  Proof.
    clear.
    elim: n s => // n ih s /=.
    apply: rbindP => // [[s' sci]] h.
    case: (boolP (Sv.subset _ _)) => //=.
    + move=> /Sv.subset_spec Hsub k; apply ok_inj in k; subst.
      exists s, s'; split; auto. SvD.fsetdec.
    move=> _ hloop; case: (ih _ hloop) => si [si'] [Hsub] [h' le].
    exists si, si'; split; auto. SvD.fsetdec.
  Qed.

  Local Lemma Hwhile_true : sem_Ind_while_true p ev Pc Pi_r.
  Proof.
    move=> s1 s2 s3 s4 a c e c' Hsc Hc H Hsc' Hc' Hsw Hw ii /= sv0.
    set dobody := (X in wloop X).
    case Hloop: wloop => [[sv1 [c1 c1']] /=|//].
    move: (wloopP Hloop) => [sv2 [sv2' [H1 [H2 H2']]]] Hwf vm1' Hvm.
    apply: rbindP H2 => -[sv3 c2'] Hc2'.
    set sv4 := read_e_rec _ _ in Hc2'.
    apply: rbindP => -[ sv5 c2 ] Hc2 x; apply ok_inj in x.
    repeat (case/xseq.pair_inj: x => ? x; subst).
    have := Hc sv4; rewrite Hc2' => /(_ Hwf vm1') [|vm2' [Hvm2'1 Hvm2'2]].
    + by apply: vmap_uincl_onI Hvm;SvD.fsetdec.
    have Hwf2 := wf_sem Hsc Hwf.
    have := Hc' sv1;rewrite Hc2=> /(_ Hwf2 vm2') [|vm3' [Hvm3'1 Hvm3'2]].
    + by apply: vmap_uincl_onI Hvm2'1;rewrite /sv4 read_eE;SvD.fsetdec.
    have Hwf3 := wf_sem Hsc' Hwf2.
    have /= := Hw ii sv0;rewrite Hloop /= => /(_ Hwf3 _ Hvm3'1) [vm4' [Hvm4'1 /semE Hvm4'2]].
    exists vm4';split => //.
    case: Hvm4'2 => si [/sem_IE Hvm4'2 /semE ?]; subst si.
    apply sem_seq1;constructor.
    apply: (Ewhile_true Hvm2'2) Hvm3'2 Hvm4'2; rewrite -?eq_globs.
    have Hvm': evm s2 <=[read_e_rec sv0 e] vm2'.
    + by apply: vmap_uincl_onI Hvm2'1; rewrite /sv4 !read_eE; SvD.fsetdec.
    have Hmem : s2 = {|emem := emem s2; evm := evm s2|}. by case: (s2).
    rewrite Hmem in H.
    have := sem_pexpr_uincl_on' Hvm2'1 H.
    move=> [v] H' Hv. rewrite /value_uincl in Hv. case: v Hv H'=> //=.
    by move=> b -> H'. 
  Qed.

  Local Lemma Hwhile_false : sem_Ind_while_false p ev Pc Pi_r.
  Proof.
    move=> s1 s2 a c e c' Hsc Hc H ii sv0 /=.
    set dobody := (X in wloop X).
    case Hloop: wloop => [[sv1 [c1 c1']] /=|//] Hwf vm1' Hvm.
    move: (wloopP Hloop) => [sv2 [sv2' [H1 [H2 H2']]]].
    apply: rbindP H2 => -[sv3 c2'] Hc2.
    set sv4 := read_e_rec _ _ in Hc2.
    apply: rbindP => -[sv5 c2] Hc2' x; apply ok_inj in x.
    repeat (case/xseq.pair_inj: x => ? x; subst).
    have := Hc sv4;rewrite Hc2 => /(_ Hwf vm1') [|vm2' [Hvm2'1 Hvm2'2]].
    + by apply: vmap_uincl_onI Hvm.
    exists vm2';split.
    + apply: vmap_uincl_onI Hvm2'1;rewrite /sv4 read_eE;SvD.fsetdec.
    apply sem_seq1;constructor.
    apply: (Ewhile_false _ _ Hvm2'2); rewrite -?eq_globs.
    have Hvm': evm s2 <=[read_e_rec sv0 e] vm2'.
    + by apply: vmap_uincl_onI Hvm2'1;rewrite /sv4 !read_eE; SvD.fsetdec.
    have Hmem : s2 = {|emem := emem s2; evm := evm s2|}. by case: (s2).
    rewrite Hmem in H.
    have := sem_pexpr_uincl_on' Hvm2'1 H.
    move=> [v] H' Hv. rewrite /value_uincl in Hv. case: v Hv H'=> //=.
    by move=> b -> H'. 
  Qed.

  Lemma loopP f ii n rx wx sv0 sv1 sc1:
    loop f ii n rx wx sv0 = ok (sv1, sc1) -> Sv.Subset sv0 sv1 /\
      exists sv2, f sv1 = ok (sv2, sc1) /\ Sv.Subset (Sv.union rx (Sv.diff sv2 wx)) sv1.
  Proof.
    elim: n sv0=> // n IH sv0 /=.
    apply: rbindP=> [[sv0' sc0']] Hone.
    case: (boolP (Sv.subset (Sv.union rx (Sv.diff sv0' wx)) sv0))=> /=.
    + move=> /Sv.subset_spec Hsub.
      rewrite /ciok=> -[??]; subst sv1 sc1;split=>//.
      by exists sv0'; split=>//; SvD.fsetdec.
    move=> _ Hloop.
    move: (IH _ Hloop)=> [Hsub [sv2 [Hsv2 Hsv2']]];split;first by SvD.fsetdec.
    by exists sv2.
  Qed.

  Local Lemma Hfor : sem_Ind_for p ev Pi_r Pfor.
  Proof.
    move=> s1 s2 i d lo hi c vlo vhi Hlo Hhi Hc Hfor ii /= sv0.
    case Hloop: (loop (dead_code_c (dead_code_i onfun) c) ii Loop.nb Sv.empty (Sv.add i Sv.empty) sv0)=> [[sv1 sc1] /=|//].
    move: (loopP Hloop)=> [H1 [sv2 [H2 H2']]] Hwf vm1' Hvm.
    move: Hfor=> /(_ sv1); rewrite H2.
    move=> /(_ H2' Hwf vm1') [|vm2' [Hvm2'1 Hvm2'2]].
    move: Hvm; rewrite !read_eE=> Hvm.
    + by apply: vmap_uincl_onI Hvm; SvD.fsetdec.
    have Hmem : s1 = {|emem := emem s1; evm := evm s1|}. by case: (s1).
    rewrite Hmem in Hlo.
    have := sem_pexpr_uincl_on' Hvm Hlo.
    move=> [v] Hlo' Hv.
    exists vm2'; split.
    + apply: vmap_uincl_onI Hvm2'1; SvD.fsetdec.
    econstructor; constructor;case: v Hv Hlo'=> //= z <- Hlo'; econstructor;
    rewrite -?eq_globs. apply Hlo'.
    rewrite Hmem in Hhi.
    + have Hvm': evm s1 <=[read_e_rec Sv.empty hi] vm1'.
      + move: Hvm; rewrite !read_eE=> Hvm.
        by apply: vmap_uincl_onI Hvm; SvD.fsetdec.
    rewrite Hmem in Hhi.
    have := sem_pexpr_uincl_on' Hvm' Hhi.
    move=> [v] Hhi' Hv. case: v Hv Hhi'=> //= z' <- Hhi'. by apply Hhi'.
    exact: Hvm2'2.
  Qed.

  Local Lemma Hfor_nil : sem_Ind_for_nil Pfor.
  Proof.
   move=> s i c sv0.
   case Heq: (dead_code_c (dead_code_i onfun) c sv0) => [[sv1 sc1]|] //= Hsub Hwf vm1' Hvm.
   exists vm1'; split=> //.
   apply: EForDone.
  Qed.

  Local Lemma Hfor_cons : sem_Ind_for_cons p ev Pc Pfor.
  Proof.
    move=> s1 s1' s2 s3 i w ws c Hw Hsc Hc Hsfor Hfor sv0.
    case Heq: (dead_code_c (dead_code_i onfun) c sv0) => [[sv1 sc1]|] //= Hsub Hwf vm1' Hvm.
    (*have [vm1'' [Hvm1''1 Hvm1''2]] := write_var_eq_on _ Hw Hvm.
    move: Hc=> /(_ sv0).
    rewrite Heq.
    have Hwf' := wf_write_var Hwf Hw.
    move=> /(_ Hwf' vm1'') [|vm2' [Hvm2'1 Hvm2'2]].
    apply: eq_onI Hvm1''1; SvD.fsetdec.
    move: Hfor=> /(_ sv0).
    rewrite Heq.
    move=> /(_ _ _ vm2') [|||vm3' [Hvm3'1 Hvm3'2]] //.
    apply: wf_sem Hsc Hwf'.
    exists vm3'; split=> //.
    econstructor.
    exact: Hvm1''2.
    exact: Hvm2'2.
    exact: Hvm3'2.*)
  Admitted.

  Lemma write_lvals_keep_only ii tokeep xs I O xs' s1 s2 vs vm1:
    check_keep_only ii xs tokeep O = ok (I, xs') ->
    write_lvals gd s1 xs vs = ok s2 ->
    evm s1 <=[I]  vm1 ->
    ∃ vm2 : vmap, evm s2 <=[O]  vm2 ∧ 
     write_lvals gd (with_vm s1 vm1) xs' (keep_only vs tokeep) = ok (with_vm s2 vm2).
  Proof.
    elim: tokeep xs xs' I s1 vs vm1 => [ | b tokeep ih] [ | x xs] //= xs' I s1 [ | v vs] // vm1.
    + by move=> [??] [?] /= ?; subst O xs' s2; exists vm1.
    t_xrbindP => -[I1 xs1] hc; case: b.
    + move=> [??] s1' hw hws heq; subst I xs'. Check write_lval_uincl_on.
      have hv : value_uincl v v. auto.
      have [] := write_lval_uincl_on _ hv hw heq.
      + by rewrite read_rvE; SvD.fsetdec.
      move=> vm1' heq' hw'.
      have [|vm2 [heqO hws']]:= ih _ _ _ _ _ vm1' hc hws.
      + by apply: vmap_uincl_onI heq'; rewrite read_rvE; SvD.fsetdec.
      by exists vm2; rewrite /= hw'.
    case:andP => //= -[hd hnmem] [??] s1' hw hws heqI; subst I1 xs1.
    have [heq1 hmem1]:= Hwrite_disj hw hd hnmem.
    have [|vm2 [heqO hws']]:= ih _ _ _ _ _ vm1 hc hws.
    + apply: vmap_uincl_onT heqI. admit.
    by rewrite /with_vm hmem1; exists vm2.
  Admitted.

  Local Lemma Hcall : sem_Ind_call p ev Pi_r Pfun.
  Proof.
    move=> s1 m2 s2 ii xs fn args vargs vs Hexpr Hcall Hfun Hw ii' sv0 /=.
    set sxs := (X in Let sxs := X in _).
    case heq: sxs => [ [I xs'] | ] //= => Hwf vm1' Hvm.
    have [vm2 [Hvm2 /= Hvm2']]: exists vm2, evm s2 <=[sv0] vm2 /\ 
             write_lvals gd (with_vm (with_mem s1 m2) vm1') xs' (fn_keep_only onfun fn vs) =
             ok (with_vm s2 vm2); first last.
    have Hmem : s1 = {|emem := emem s1; evm := evm s1|}. by case: (s1).
    rewrite Hmem in Hexpr.
    have := sem_pexprs_uincl_on' Hvm Hexpr.
    move=> [v] Hexpr' Hv.
    + exists vm2; split => //.
      econstructor; constructor; econstructor;
      rewrite -?eq_globs.
      + apply Hexpr'.
      + rewrite /with_vm /=. rewrite /Pfun in Hfun. 
        have := sem_call_uincl Hv Hfun. move=> [] v' [] Hfun' Hv'. admit.
      exact: Hvm2'.
    move: heq; rewrite /sxs /fn_keep_only; case: onfun => [tokeep | [??]].
    + move=> hc; apply: (write_lvals_keep_only hc Hw).
      by apply: vmap_uincl_onI Hvm; rewrite read_esE; SvD.fsetdec. 
      subst xs' I. (*have (*[|vm2 [Hvm2 /= Hvm2']]*) := write_lvals_uincl_on _ _ Hw Hvm.
      move=> H.
    + by rewrite read_esE read_rvsE; SvD.fsetdec.
    exists vm2; split => //.      
    by apply: eq_onI Hvm2; rewrite read_esE read_rvsE; SvD.fsetdec.*)
  Admitted.

  Local Lemma Hproc : sem_Ind_proc p ev Pc Pfun.
  Proof.
    move=> m1 m2 fn f vargs vargs' s0 s1 s2 vres vres' Hfun htra Hi Hw Hsem Hc Hres Hfull Hfi.
    have dcok : map_cfprog_name (dead_code_fd onfun) (p_funcs p) = ok (p_funcs p').
    + by move: dead_code_ok; rewrite /dead_code_prog_tokeep; t_xrbindP => ? ? <-.
    have [f' Hf'1 Hf'2] := get_map_cfprog_name dcok Hfun.
    case: f Hf'1 Hfun htra Hi Hw Hsem Hc Hres Hfull Hfi => ??? /= c f_tyout res ? Hf'1 Hfun htra Hi Hw Hsem Hc Hres Hfull Hfi.
    move: Hf'1; t_xrbindP => -[sv sc] Hd [?]; subst f'.
    move: Hc => /(_ (read_es [seq Plvar i | i <- fn_keep_only onfun fn res])); rewrite Hd.
    move=> /(_ (wf_write_vars (wf_init Hi wf_vmap0) Hw) (evm s1)) => -[// | vm2' [Hvm2'1 /= ]].
    rewrite with_vm_same => Hvm2'2.
    eapply (EcallRun (vres := fn_keep_only onfun fn vres) (vres' := fn_keep_only onfun fn vres')); eauto.
    + by rewrite -eq_p_extra; exact Hi.
    + rewrite /= -(evm_with_vm s2 vm2') -(sem_pexprs_get_var gd).
      move: Hres Hvm2'1; rewrite -(sem_pexprs_get_var gd).
      rewrite /fn_keep_only; case: onfun => [tokeep | ]; last first.
      (*+ by move=> <- h. rewrite (read_es_eq_on _ h).
      clear; elim: tokeep res vres => /= [ | b tokeep ih].
      + by move=> ?? <- h; rewrite (read_es_eq_on _ h).      
      move=> [ | x res] vres /= => [[<-] //|].
      t_xrbindP => v hget vs hvs <-; case: b => /= heq; last by apply ih.
      have <- := get_gvar_eq_on gd (v:= mk_lvar x) _ heq.
      + by rewrite hget /= (ih _ _ hvs) //; apply: eq_onI heq; rewrite read_es_cons; SvD.fsetdec.
      by rewrite read_es_cons /= /Plvar read_e_var; SvD.fsetdec.
    rewrite /= /fn_keep_only; case: onfun => [tokeep | //].
    move:Hfull; clear.
    elim: tokeep f_tyout vres vres' => // b tokeep ih [| ty f_tyout] /= [ | v vres] //= vres' => [[<-]//|].
    by t_xrbindP => v' hv' vres1 /ih{ih}ih <-; case:b => //=; rewrite hv' /= ih.
  Qed.*) Admitted.

  Lemma dead_code_callP fn mem mem' va vr:
    sem_call p ev mem fn va mem' vr ->
    sem_call p' ev mem fn va mem' (fn_keep_only onfun fn vr).
  Proof.
    apply (@sem_call_Ind _ _ _ p ev Pc Pi_r Pi Pfor Pfun Hskip Hcons HmkI Hassgn Hopn
            Hif_true Hif_false Hwhile_true Hwhile_false Hfor Hfor_nil Hfor_cons Hcall Hproc).
  Qed.

End PROOF.

End Section.

Lemma dead_code_tokeep_callPu (p p': uprog) onfun fn ev mem mem' va vr:
  dead_code_prog_tokeep onfun p = ok p' ->
  sem_call p ev mem fn va mem' vr ->
  sem_call p' ev mem fn va mem' (fn_keep_only onfun fn vr).
Proof. move=> hd;apply: dead_code_callP => //; apply wf_initu. Qed.

Lemma dead_code_tokeep_callPs (p p': sprog) onfun fn wrip mem mem' va vr:
  dead_code_prog_tokeep onfun p = ok p' ->
  sem_call p wrip mem fn va mem' vr ->
  sem_call p' wrip mem fn va mem' (fn_keep_only onfun fn vr).
Proof. move=> hd;apply: dead_code_callP => //; apply wf_inits. Qed.

Lemma dead_code_callPu (p p': uprog) fn ev mem mem' va vr:
  dead_code_prog p = ok p' ->
  sem_call p ev mem fn va mem' vr ->
  sem_call p' ev mem fn va mem' vr.
Proof. apply dead_code_tokeep_callPu. Qed.

Lemma dead_code_callPs (p p': sprog) fn wrip mem mem' va vr:
  dead_code_prog p = ok p' ->
  sem_call p wrip mem fn va mem' vr ->
  sem_call p' wrip mem fn va mem' vr.
Proof. apply dead_code_tokeep_callPs. Qed.

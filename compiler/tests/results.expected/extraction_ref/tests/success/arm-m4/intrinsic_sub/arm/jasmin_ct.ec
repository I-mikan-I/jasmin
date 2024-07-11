require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_m4.
import SLH32.

from Jasmin require import JLeakage.



module M = {
  var leakages : leakages_t
  
  proc sub (arg0:W32.t, arg1:W32.t) : W32.t = {
    var aux_3: bool;
    var aux_2: bool;
    var aux_1: bool;
    var aux_0: bool;
    var aux: W32.t;
    
    var res_0:W32.t;
    var x:W32.t;
    var nf:bool;
    var zf:bool;
    var cf:bool;
    var vf:bool;
    var _nf_:bool;
    var _zf_:bool;
    var _cf_:bool;
    var _vf_:bool;
    
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 arg1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (W32.of_int 1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (W32.of_int (- 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB x (W32.of_int 3402287818);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB x (W32.of_int 3389049344);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB x (W32.of_int 13238474);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB x (W32.of_int 831488);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB x (W32.of_int 2762);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `<<` (W8.of_int 0));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `<<` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `<<` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `>>` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `>>` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `|>>` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `|>>` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `|>>|` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUB arg0 (arg1 `|>>|` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x arg0;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (! zf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 cf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (! cf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 nf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (! nf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 vf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (! vf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (cf /\ (! zf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 ((! cf) \/ zf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (nf = vf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (! (nf = vf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 ((! zf) /\ (nf = vf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc arg0 arg1 (zf \/ (! (nf = vf))) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBScc x arg0 (nf = vf) nf zf cf vf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (W32.of_int 2);
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (W32.of_int 3402287818);
    _nf_ <- aux_3;
    _zf_ <- aux_2;
    _cf_ <- aux_1;
    _vf_ <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (W32.of_int 3389049344);
    _nf_ <- aux_3;
    _zf_ <- aux_2;
    _cf_ <- aux_1;
    _vf_ <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (W32.of_int 13238474);
    _nf_ <- aux_3;
    _zf_ <- aux_2;
    _cf_ <- aux_1;
    _vf_ <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (W32.of_int 13303808);
    _nf_ <- aux_3;
    _zf_ <- aux_2;
    _cf_ <- aux_1;
    _vf_ <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (arg0 `<<` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (arg0 `>>` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (arg0 `|>>` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (arg0 `|>>|` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBScc x (W32.of_int 2) (nf = vf) nf zf cf vf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBScc x (arg0 `<<` (W8.of_int 3)) (nf = vf) nf zf cf vf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBScc x (arg0 `<<` (W8.of_int 3)) (! (! (nf = vf))) nf zf cf vf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBScc x (arg0 `>>` (W8.of_int 3)) (nf = vf) nf zf cf vf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBScc x (arg0 `|>>` (W8.of_int 3)) (nf = vf) nf zf cf vf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBScc x (arg0 `|>>|` (W8.of_int 3)) (nf = vf) nf zf cf vf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x arg0 (! (! (! (! zf)))) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x (W32.of_int 2) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x (W32.of_int 2) (! (! zf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x (arg0 `<<` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x (arg0 `<<` (W8.of_int 3)) (! (! zf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x (arg0 `>>` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x (arg0 `|>>` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- SUBcc x (arg0 `|>>|` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    res_0 <- aux;
    return (res_0);
  }
}.


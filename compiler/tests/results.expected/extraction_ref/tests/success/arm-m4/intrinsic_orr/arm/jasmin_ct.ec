require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_m4.
import SLH32.

from Jasmin require import JLeakage.



module M = {
  var leakages : leakages_t
  
  proc orr (arg0:W32.t, arg1:W32.t) : W32.t = {
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
    
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 arg1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (W32.of_int 1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (W32.of_int (- 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR x (W32.of_int 3402287818);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR x (W32.of_int 3389049344);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR x (W32.of_int 13238474);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `<<` (W8.of_int 0));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `<<` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `<<` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `>>` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `>>` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `|>>` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `|>>` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `|>>|` (W8.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORR arg0 (arg1 `|>>|` (W8.of_int 31));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x arg0;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0) <- CMP x (W32.of_int 0);
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (! zf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 cf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (! cf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 nf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (! nf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 vf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (! vf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (cf /\ (! zf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 ((! cf) \/ zf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (nf = vf) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (! (nf = vf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 ((! zf) /\ (nf = vf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc arg0 arg1 (zf \/ (! (nf = vf))) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRScc x arg0 (nf = vf) nf zf cf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (W32.of_int 2);
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (W32.of_int 3402287818);
    _nf_ <- aux_3;
    _zf_ <- aux_2;
    _cf_ <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (W32.of_int 3389049344);
    _nf_ <- aux_3;
    _zf_ <- aux_2;
    _cf_ <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (W32.of_int 13238474);
    _nf_ <- aux_3;
    _zf_ <- aux_2;
    _cf_ <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (arg0 `<<` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (arg0 `>>` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (arg0 `|>>` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRS x (arg0 `|>>|` (W8.of_int 3));
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRScc x (W32.of_int 2) (nf = vf) nf zf cf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRScc x (arg0 `<<` (W8.of_int 3)) (nf = vf) nf zf cf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRScc x (arg0 `<<` (W8.of_int 3)) (! (! (nf = vf))) nf zf cf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRScc x (arg0 `>>` (W8.of_int 3)) (nf = vf) nf zf cf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRScc x (arg0 `|>>` (W8.of_int 3)) (nf = vf) nf zf cf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux) <- ORRScc x (arg0 `|>>|` (W8.of_int 3)) (nf = vf) nf zf cf x;
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x arg0 (! (! (! (! zf)))) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x (W32.of_int 2) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x (W32.of_int 2) (! (! zf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x (arg0 `<<` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x (arg0 `<<` (W8.of_int 3)) (! (! zf)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x (arg0 `>>` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x (arg0 `|>>` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ORRcc x (arg0 `|>>|` (W8.of_int 3)) zf x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    res_0 <- aux;
    return (res_0);
  }
}.


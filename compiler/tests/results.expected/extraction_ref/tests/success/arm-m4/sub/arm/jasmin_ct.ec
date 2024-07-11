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
    var  _0:W32.t;
    
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - arg1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (W32.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (W32.of_int 1));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (W32.of_int (- 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (W32.of_int (- 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (W32.of_int 3402287818));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (W32.of_int 3389049344));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (W32.of_int 13238474));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (W32.of_int 831488));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (W32.of_int 2762));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `<<` (W8.of_int 0)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `<<` (W8.of_int 0)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `<<` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `<<` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `<<` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `<<` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `>>` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `>>` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `>>` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `>>` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `|>>` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `|>>` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `|>>` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `|>>` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `|>>|` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `|>>|` (W8.of_int 1)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- (arg0 - (arg1 `|>>|` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (x - (arg0 `|>>|` (W8.of_int 31)));
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((arg0 `<<` (W8.of_int 0)) - arg1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((arg0 `|>>|` (W8.of_int 1)) - arg1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((arg0 `|>>` (W8.of_int 2)) - arg1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((arg0 `>>` (W8.of_int 3)) - arg1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    leakages <- LeakAddr([(W32.to_uint (x + (W32.of_int 0)))]) :: leakages;
    Glob.mem <- storeW32 Glob.mem (W32.to_uint (x + (W32.of_int 0))) (aux);
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0, aux) <- SUBS x (W32.of_int 0);
    nf <- aux_3;
    zf <- aux_2;
    cf <- aux_1;
    vf <- aux_0;
     _0 <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (zf ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (zf ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! zf) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! zf) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (cf ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (cf ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! cf) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! cf) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (nf ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (nf ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! nf) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! nf) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (vf ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (vf ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! vf) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! vf) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((cf /\ (! zf)) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((cf /\ (! zf)) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (((! cf) \/ zf) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (((! cf) \/ zf) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((nf = vf) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((nf = vf) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! (nf = vf)) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! (nf = vf)) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (((! zf) /\ (nf = vf)) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (((! zf) /\ (nf = vf)) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((zf \/ (! (nf = vf))) ? (arg0 - arg1) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((zf \/ (! (nf = vf))) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! (! (! (! zf)))) ? (x - arg0) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (zf ? (x - (W32.of_int 2)) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! (! zf)) ? (x - (W32.of_int 2)) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (zf ? (x - (arg0 `<<` (W8.of_int 3))) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- ((! ((! (! zf)) \/ (! (nf = vf)))) ? (x - (arg0 `<<` (W8.of_int 3))) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (zf ? (x - (arg0 `>>` (W8.of_int 3))) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (zf ? (x - (arg0 `|>>` (W8.of_int 3))) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (zf ? (x - (arg0 `|>>|` (W8.of_int 3))) : x);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    res_0 <- aux;
    return (res_0);
  }
}.


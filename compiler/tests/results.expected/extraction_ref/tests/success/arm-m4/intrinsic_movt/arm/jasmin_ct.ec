require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_m4.
import SLH32.

from Jasmin require import JLeakage.



module M = {
  var leakages : leakages_t
  
  proc movt () : W32.t = {
    var aux_3: bool;
    var aux_2: bool;
    var aux_1: bool;
    var aux_0: bool;
    var aux: W32.t;
    
    var res_0:W32.t;
    var x:W32.t;
    var n:bool;
    var z:bool;
    var c:bool;
    var v:bool;
    
    leakages <- LeakAddr([]) :: leakages;
    aux <- (W32.of_int 0);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVT x (W16.of_int 0);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVT x (W16.of_int 1);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVT x (W16.of_int 65535);
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    (aux_3, aux_2, aux_1, aux_0) <- CMP x (W32.of_int 0);
    n <- aux_3;
    z <- aux_2;
    c <- aux_1;
    v <- aux_0;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) z x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (! z) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) c x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (! c) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) n x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (! n) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) v x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (! v) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (c /\ (! z)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) ((! c) \/ z) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (n = v) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (! (n = v)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) ((! z) /\ (n = v)) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- MOVTcc x (W16.of_int 3) (z \/ (! (n = v))) x;
    x <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- x;
    res_0 <- aux;
    return (res_0);
  }
}.


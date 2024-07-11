require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_m4.
import SLH32.





module M = {
  proc smmulr (arg0:W32.t, arg1:W32.t) : W32.t = {
    
    var res_0:W32.t;
    var x:W32.t;
    var n:bool;
    var z:bool;
    var c:bool;
    var v:bool;
    
    x <- SMMULR arg0 arg1;
    (n, z, c, v) <- CMP x (W32.of_int 0);
    x <- SMMULRcc x arg0 z x;
    x <- SMMULRcc x arg0 (! z) x;
    x <- SMMULRcc x arg0 c x;
    x <- SMMULRcc x arg0 (! c) x;
    x <- SMMULRcc x arg0 n x;
    x <- SMMULRcc x arg0 (! n) x;
    x <- SMMULRcc x arg0 v x;
    x <- SMMULRcc x arg0 (! v) x;
    x <- SMMULRcc x arg0 (c /\ (! z)) x;
    x <- SMMULRcc x arg0 ((! c) \/ z) x;
    x <- SMMULRcc x arg0 (n = v) x;
    x <- SMMULRcc x arg0 (! (n = v)) x;
    x <- SMMULRcc x arg0 ((! z) /\ (n = v)) x;
    x <- SMMULRcc x arg0 (z \/ (! (n = v))) x;
    res_0 <- x;
    return (res_0);
  }
}.


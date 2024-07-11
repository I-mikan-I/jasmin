require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_m4.
import SLH32.





module M = {
  proc ldrh (arg:W32.t) : W32.t = {
    
    var res_0:W32.t;
    var x:W32.t;
    var n:bool;
    var z:bool;
    var c:bool;
    var v:bool;
    
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (arg + (W32.of_int 0))));
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 2))));
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (x + (- (W32.of_int 2)))));
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (x + arg)));
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (x + (arg * (W32.of_int 1)))));
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (x + (arg * (W32.of_int 2)))));
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (x + (arg * (W32.of_int 4)))));
    x <- LDRH (loadW16 Glob.mem (W32.to_uint (x + (arg * (W32.of_int 8)))));
    (n, z, c, v) <- CMP x (W32.of_int 0);
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) z x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (! z) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) c x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (! c) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) n x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (! n) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) v x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (! v) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (c /\ (! z)) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) ((! c) \/ z) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (n = v) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (! (n = v)) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) ((! z) /\ (n = v)) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 0)))) (z \/ (! (n = v))) x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + arg))) z x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (W32.of_int 3)))) z x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (- (W32.of_int 3))))) z x;
    x <- LDRHcc (loadW16 Glob.mem (W32.to_uint (x + (arg * (W32.of_int 2))))) z x;
    res_0 <- x;
    return (res_0);
  }
}.


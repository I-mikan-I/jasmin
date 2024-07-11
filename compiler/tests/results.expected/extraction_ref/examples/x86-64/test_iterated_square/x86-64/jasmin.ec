require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_x86.
import SLH64.


require import Array4 Array5 Array8.
require import WArray32 WArray40 WArray64.

abbrev __38 = W64.of_int 38.


module M = {
  proc reduce (z:W64.t Array8.t) : W64.t Array4.t = {
    var aux: bool;
    var aux_0: W64.t;
    
    var xa:W64.t Array4.t;
    var rax:W64.t;
    var rdx:W64.t;
    var cf:bool;
    var z8:W64.t;
    var r0:W64.t;
    var  _0:bool;
    var  _1:bool;
    var  _2:bool;
    var  _3:bool;
    var  _4:bool;
    xa <- witness;
    rax <- z.[4];
    (rdx, rax) <- mulu_64 rax __38;
    xa.[0] <- rax;
    xa.[1] <- rdx;
    rax <- z.[5];
    (rdx, rax) <- mulu_64 rax __38;
    (aux, aux_0) <- adc_64 xa.[1] rax false;
    cf <- aux;
    xa.[1] <- aux_0;
    xa.[2] <- MOV_64 (W64.of_int 0);
    rax <- z.[6];
    (aux, aux_0) <- adc_64 xa.[2] rdx cf;
     _0 <- aux;
    xa.[2] <- aux_0;
    (rdx, rax) <- mulu_64 rax __38;
    (aux, aux_0) <- adc_64 xa.[2] rax false;
    cf <- aux;
    xa.[2] <- aux_0;
    xa.[3] <- MOV_64 (W64.of_int 0);
    rax <- z.[7];
    (aux, aux_0) <- adc_64 xa.[3] rdx cf;
     _1 <- aux;
    xa.[3] <- aux_0;
    (rdx, rax) <- mulu_64 rax __38;
    (aux, aux_0) <- adc_64 xa.[3] rax false;
    cf <- aux;
    xa.[3] <- aux_0;
    z8 <- MOV_64 (W64.of_int 0);
    ( _2, z8) <- adc_64 z8 rdx cf;
    (aux, aux_0) <- adc_64 xa.[0] z.[0] false;
    cf <- aux;
    xa.[0] <- aux_0;
    (aux, aux_0) <- adc_64 xa.[1] z.[1] cf;
    cf <- aux;
    xa.[1] <- aux_0;
    (aux, aux_0) <- adc_64 xa.[2] z.[2] cf;
    cf <- aux;
    xa.[2] <- aux_0;
    (aux, aux_0) <- adc_64 xa.[3] z.[3] cf;
    cf <- aux;
    xa.[3] <- aux_0;
    ( _3, z8) <- adc_64 z8 (W64.of_int 0) cf;
    z8 <- (z8 * (W64.of_int 38));
    r0 <- MOV_64 (W64.of_int 0);
    (aux, aux_0) <- adc_64 xa.[0] z8 false;
    cf <- aux;
    xa.[0] <- aux_0;
    (aux, aux_0) <- adc_64 xa.[1] (W64.of_int 0) cf;
    cf <- aux;
    xa.[1] <- aux_0;
    (aux, aux_0) <- adc_64 xa.[2] (W64.of_int 0) cf;
    cf <- aux;
    xa.[2] <- aux_0;
    (aux, aux_0) <- adc_64 xa.[3] (W64.of_int 0) cf;
    cf <- aux;
    xa.[3] <- aux_0;
    ( _4, r0) <- adc_64 r0 (W64.of_int 0) cf;
    r0 <- (r0 * (W64.of_int 38));
    xa.[0] <- (xa.[0] + r0);
    return (xa);
  }
  
  proc iterated_square (xa:W64.t Array4.t, n:W64.t) : W64.t Array4.t = {
    var aux: bool;
    var aux_0: W64.t;
    
    var cf:bool;
    var z:W64.t Array8.t;
    var rax:W64.t;
    var rdx:W64.t;
    var t:W64.t Array5.t;
    var t2s:W64.t;
    var  _0:bool;
    var  _1:bool;
    var  _2:bool;
    var  _3:bool;
    var  _4:bool;
    t <- witness;
    z <- witness;
    z <- witness;
    rax <- xa.[1];
    (rdx, rax) <- mulu_64 rax xa.[0];
    z.[1] <- rax;
    z.[2] <- rdx;
    rax <- xa.[2];
    (rdx, rax) <- mulu_64 rax xa.[1];
    z.[3] <- rax;
    z.[4] <- rdx;
    rax <- xa.[3];
    (rdx, rax) <- mulu_64 rax xa.[2];
    z.[5] <- rax;
    z.[6] <- rdx;
    z.[7] <- MOV_64 (W64.of_int 0);
    rax <- xa.[2];
    (rdx, rax) <- mulu_64 rax xa.[0];
    (aux, aux_0) <- adc_64 z.[2] rax false;
    cf <- aux;
    z.[2] <- aux_0;
    (aux, aux_0) <- adc_64 z.[3] rdx cf;
    cf <- aux;
    z.[3] <- aux_0;
    (aux, aux_0) <- adc_64 z.[4] (W64.of_int 0) cf;
     _0 <- aux;
    z.[4] <- aux_0;
    rax <- xa.[3];
    (rdx, rax) <- mulu_64 rax xa.[1];
    (aux, aux_0) <- adc_64 z.[4] rax false;
    cf <- aux;
    z.[4] <- aux_0;
    (aux, aux_0) <- adc_64 z.[5] rdx cf;
    cf <- aux;
    z.[5] <- aux_0;
    (aux, aux_0) <- adc_64 z.[6] (W64.of_int 0) cf;
    cf <- aux;
    z.[6] <- aux_0;
    rax <- xa.[3];
    (rdx, rax) <- mulu_64 rax xa.[0];
    (aux, aux_0) <- adc_64 z.[3] rax false;
    cf <- aux;
    z.[3] <- aux_0;
    (aux, aux_0) <- adc_64 z.[4] rdx cf;
    cf <- aux;
    z.[4] <- aux_0;
    (aux, aux_0) <- adc_64 z.[5] (W64.of_int 0) cf;
    cf <- aux;
    z.[5] <- aux_0;
    (aux, aux_0) <- adc_64 z.[6] (W64.of_int 0) cf;
    cf <- aux;
    z.[6] <- aux_0;
    (aux, aux_0) <- adc_64 z.[7] (W64.of_int 0) cf;
     _1 <- aux;
    z.[7] <- aux_0;
    (aux, aux_0) <- adc_64 z.[1] z.[1] false;
    cf <- aux;
    z.[1] <- aux_0;
    (aux, aux_0) <- adc_64 z.[2] z.[2] cf;
    cf <- aux;
    z.[2] <- aux_0;
    (aux, aux_0) <- adc_64 z.[3] z.[3] cf;
    cf <- aux;
    z.[3] <- aux_0;
    (aux, aux_0) <- adc_64 z.[4] z.[4] cf;
    cf <- aux;
    z.[4] <- aux_0;
    (aux, aux_0) <- adc_64 z.[5] z.[5] cf;
    cf <- aux;
    z.[5] <- aux_0;
    (aux, aux_0) <- adc_64 z.[6] z.[6] cf;
    cf <- aux;
    z.[6] <- aux_0;
    (aux, aux_0) <- adc_64 z.[7] z.[7] cf;
     _2 <- aux;
    z.[7] <- aux_0;
    rax <- xa.[0];
    (rdx, rax) <- mulu_64 rax xa.[0];
    z.[0] <- rax;
    t.[0] <- rdx;
    rax <- xa.[1];
    (rdx, rax) <- mulu_64 rax xa.[1];
    t.[1] <- rax;
    t2s <- rdx;
    rax <- xa.[2];
    (rdx, rax) <- mulu_64 rax xa.[2];
    t.[3] <- rax;
    t.[4] <- rdx;
    t.[2] <- t2s;
    (aux, aux_0) <- adc_64 z.[1] t.[0] false;
    cf <- aux;
    z.[1] <- aux_0;
    (aux, aux_0) <- adc_64 z.[2] t.[1] cf;
    cf <- aux;
    z.[2] <- aux_0;
    (aux, aux_0) <- adc_64 z.[3] t.[2] cf;
    cf <- aux;
    z.[3] <- aux_0;
    (aux, aux_0) <- adc_64 z.[4] t.[3] cf;
    cf <- aux;
    z.[4] <- aux_0;
    (aux, aux_0) <- adc_64 z.[5] t.[4] cf;
    cf <- aux;
    z.[5] <- aux_0;
    (aux, aux_0) <- adc_64 z.[6] (W64.of_int 0) cf;
    cf <- aux;
    z.[6] <- aux_0;
    (aux, aux_0) <- adc_64 z.[7] (W64.of_int 0) cf;
     _3 <- aux;
    z.[7] <- aux_0;
    rax <- xa.[3];
    (rdx, rax) <- mulu_64 rax xa.[3];
    (aux, aux_0) <- adc_64 z.[6] rax false;
    cf <- aux;
    z.[6] <- aux_0;
    (aux, aux_0) <- adc_64 z.[7] rdx cf;
     _4 <- aux;
    z.[7] <- aux_0;
    xa <@ reduce (z);
    (cf, n) <- sbb_64 n (W64.of_int 1) false;
    while ((! cf)) {
      z <- witness;
      rax <- xa.[1];
      (rdx, rax) <- mulu_64 rax xa.[0];
      z.[1] <- rax;
      z.[2] <- rdx;
      rax <- xa.[2];
      (rdx, rax) <- mulu_64 rax xa.[1];
      z.[3] <- rax;
      z.[4] <- rdx;
      rax <- xa.[3];
      (rdx, rax) <- mulu_64 rax xa.[2];
      z.[5] <- rax;
      z.[6] <- rdx;
      z.[7] <- MOV_64 (W64.of_int 0);
      rax <- xa.[2];
      (rdx, rax) <- mulu_64 rax xa.[0];
      (aux, aux_0) <- adc_64 z.[2] rax false;
      cf <- aux;
      z.[2] <- aux_0;
      (aux, aux_0) <- adc_64 z.[3] rdx cf;
      cf <- aux;
      z.[3] <- aux_0;
      (aux, aux_0) <- adc_64 z.[4] (W64.of_int 0) cf;
       _0 <- aux;
      z.[4] <- aux_0;
      rax <- xa.[3];
      (rdx, rax) <- mulu_64 rax xa.[1];
      (aux, aux_0) <- adc_64 z.[4] rax false;
      cf <- aux;
      z.[4] <- aux_0;
      (aux, aux_0) <- adc_64 z.[5] rdx cf;
      cf <- aux;
      z.[5] <- aux_0;
      (aux, aux_0) <- adc_64 z.[6] (W64.of_int 0) cf;
      cf <- aux;
      z.[6] <- aux_0;
      rax <- xa.[3];
      (rdx, rax) <- mulu_64 rax xa.[0];
      (aux, aux_0) <- adc_64 z.[3] rax false;
      cf <- aux;
      z.[3] <- aux_0;
      (aux, aux_0) <- adc_64 z.[4] rdx cf;
      cf <- aux;
      z.[4] <- aux_0;
      (aux, aux_0) <- adc_64 z.[5] (W64.of_int 0) cf;
      cf <- aux;
      z.[5] <- aux_0;
      (aux, aux_0) <- adc_64 z.[6] (W64.of_int 0) cf;
      cf <- aux;
      z.[6] <- aux_0;
      (aux, aux_0) <- adc_64 z.[7] (W64.of_int 0) cf;
       _1 <- aux;
      z.[7] <- aux_0;
      (aux, aux_0) <- adc_64 z.[1] z.[1] false;
      cf <- aux;
      z.[1] <- aux_0;
      (aux, aux_0) <- adc_64 z.[2] z.[2] cf;
      cf <- aux;
      z.[2] <- aux_0;
      (aux, aux_0) <- adc_64 z.[3] z.[3] cf;
      cf <- aux;
      z.[3] <- aux_0;
      (aux, aux_0) <- adc_64 z.[4] z.[4] cf;
      cf <- aux;
      z.[4] <- aux_0;
      (aux, aux_0) <- adc_64 z.[5] z.[5] cf;
      cf <- aux;
      z.[5] <- aux_0;
      (aux, aux_0) <- adc_64 z.[6] z.[6] cf;
      cf <- aux;
      z.[6] <- aux_0;
      (aux, aux_0) <- adc_64 z.[7] z.[7] cf;
       _2 <- aux;
      z.[7] <- aux_0;
      rax <- xa.[0];
      (rdx, rax) <- mulu_64 rax xa.[0];
      z.[0] <- rax;
      t.[0] <- rdx;
      rax <- xa.[1];
      (rdx, rax) <- mulu_64 rax xa.[1];
      t.[1] <- rax;
      t2s <- rdx;
      rax <- xa.[2];
      (rdx, rax) <- mulu_64 rax xa.[2];
      t.[3] <- rax;
      t.[4] <- rdx;
      t.[2] <- t2s;
      (aux, aux_0) <- adc_64 z.[1] t.[0] false;
      cf <- aux;
      z.[1] <- aux_0;
      (aux, aux_0) <- adc_64 z.[2] t.[1] cf;
      cf <- aux;
      z.[2] <- aux_0;
      (aux, aux_0) <- adc_64 z.[3] t.[2] cf;
      cf <- aux;
      z.[3] <- aux_0;
      (aux, aux_0) <- adc_64 z.[4] t.[3] cf;
      cf <- aux;
      z.[4] <- aux_0;
      (aux, aux_0) <- adc_64 z.[5] t.[4] cf;
      cf <- aux;
      z.[5] <- aux_0;
      (aux, aux_0) <- adc_64 z.[6] (W64.of_int 0) cf;
      cf <- aux;
      z.[6] <- aux_0;
      (aux, aux_0) <- adc_64 z.[7] (W64.of_int 0) cf;
       _3 <- aux;
      z.[7] <- aux_0;
      rax <- xa.[3];
      (rdx, rax) <- mulu_64 rax xa.[3];
      (aux, aux_0) <- adc_64 z.[6] rax false;
      cf <- aux;
      z.[6] <- aux_0;
      (aux, aux_0) <- adc_64 z.[7] rdx cf;
       _4 <- aux;
      z.[7] <- aux_0;
      xa <@ reduce (z);
      (cf, n) <- sbb_64 n (W64.of_int 1) false;
    }
    return (xa);
  }
  
  proc iterated_square_export (xap:W64.t, n:W64.t) : unit = {
    
    var xa:W64.t Array4.t;
    var ns:W64.t;
    xa <- witness;
    xa.[0] <- (loadW64 Glob.mem (W64.to_uint (xap + (W64.of_int 0))));
    xa.[1] <- (loadW64 Glob.mem (W64.to_uint (xap + (W64.of_int 8))));
    xa.[2] <- (loadW64 Glob.mem (W64.to_uint (xap + (W64.of_int 16))));
    xa.[3] <- (loadW64 Glob.mem (W64.to_uint (xap + (W64.of_int 24))));
    ns <- n;
    xa <@ iterated_square (xa, ns);
    Glob.mem <- storeW64 Glob.mem (W64.to_uint (xap + (W64.of_int 0))) (xa.[0]);
    Glob.mem <- storeW64 Glob.mem (W64.to_uint (xap + (W64.of_int 8))) (xa.[1]);
    Glob.mem <- storeW64 Glob.mem (W64.to_uint (xap + (W64.of_int 16))) (xa.[2]);
    Glob.mem <- storeW64 Glob.mem (W64.to_uint (xap + (W64.of_int 24))) (xa.[3]);
    return ();
  }
}.


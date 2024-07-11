require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_m4.
import SLH32.

from Jasmin require import JLeakage.
require import Array10.
require import WArray10.

abbrev test = Array10.of_list witness [W8.of_int 84; W8.of_int 101; W8.of_int 115; W8.of_int 116; W8.of_int 115; W8.of_int 116; W8.of_int 114; W8.of_int 105; W8.of_int 110; W8.of_int 103].


module M = {
  var leakages : leakages_t
  
  proc main () : W32.t = {
    var aux: W32.t;
    
    var res_0:W32.t;
    var tmp:W32.t;
    
    leakages <- LeakAddr([]) :: leakages;
    aux <- (W32.of_int 84);
    res_0 <- aux;
    leakages <- LeakAddr([0]) :: leakages;
    aux <- (zeroextu32 test.[0]);
    tmp <- aux;
    leakages <- LeakAddr([]) :: leakages;
    aux <- (res_0 `^` tmp);
    res_0 <- aux;
    return (res_0);
  }
}.


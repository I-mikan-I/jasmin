require import AllCore IntDiv CoreMap List Distr.
from Jasmin require import JModel_x86.
import SLH64.





module M = {
  proc a__main (x:W32.t) : W32.t = {
    
    
    
    x <- x;
    return (x);
  }
  
  proc b__main (x:W32.t, y:W32.t) : W32.t = {
    
    
    
    x <- x;
    x <- (x + y);
    return (x);
  }
}.


let  g1  ::  (exists a . (a,a->Int)) -> Int
     g2  ::  (exists a . ((a,a),(a,a)->Int)) -> Int
     f   =   \h  ->  let  x1  =  g1 h
                          x2  =  g2 h
                     in   3
in   3

let  data Bool = False | True
     fst = \(a,b) -> a
     snd = \(a,b) -> b
     in
let  class Eq a where
       eq :: a -> a -> Bool
     in
let  instance dEqInt1 <: Eq Int where
       eq = \_ _ -> True
     instance dEqInt2 <: Eq Int where
       eq = \_ _ -> False
     in
let  f :: Eq a => a -> a -> Eq b => b -> b -> (Bool,Bool)
     f = \p q r s -> (eq p q, eq r s)
     in
let  v = f 3 4 5 6
in   fst v

-- data fields consistency: wrong
-- %% inline test (prefix1) --

data X
  = X { b :: Int, a, c :: Char }
  | Y { b :: Char }

-- x1 = X { c = 'y', a = 'x', b = 444 }
x1 = X 3 'z' 'a'

main = c x1

{-# LANGUAGE DeriveShow #-}

-- | Polynomials
-- A polynomial is a sum of monomials (stored in normalized form).

module LiquidLean.Polynomial.Polynomial
  ( Polynomial (..)
  , polyDegree
  , polyAdd
  , polyMul
  , polyZero
  , polyConst
  , polyVar
  , polyNormalize
  ) where

import qualified Data.Map as M
import LiquidLean.Polynomial.Monomial
import LiquidLean.Polynomial.Rational

-- | Polynomial: list of monomials in normalized form
-- Normalized = no duplicate exponent vectors, no zero coefficients
data Polynomial = Polynomial
  { polyMonomials :: [Monomial]
  , polyDimension :: Int  -- Number of variables
  } deriving (Show, Eq)

-- | Degree of polynomial (maximum degree of all monomials)
polyDegree :: Polynomial -> Integer
polyDegree p = case polyMonomials p of
  [] -> 0
  ms -> maximum (map monomialDegree ms)

-- | Add two polynomials
polyAdd :: Polynomial -> Polynomial -> Polynomial
polyAdd p1 p2 =
  polyNormalize (Polynomial
    (polyMonomials p1 ++ polyMonomials p2)
    (max (polyDimension p1) (polyDimension p2)))

-- | Multiply two polynomials
-- (a + b) * (c + d) = ac + ad + bc + bd
polyMul :: Polynomial -> Polynomial -> Polynomial
polyMul p1 p2 =
  let products = [monomialMultiply m1 m2 | m1 <- polyMonomials p1, m2 <- polyMonomials p2]
  in polyNormalize (Polynomial products (max (polyDimension p1) (polyDimension p2)))

-- | THEOREM: Degree Multiplication Bound
-- deg(P * Q) ≤ deg(P) + deg(Q)
degreeMultiplicationBound :: Polynomial -> Polynomial -> Bool
degreeMultiplicationBound p q =
  polyDegree (polyMul p q) <= polyDegree p + polyDegree q

-- | Zero polynomial
polyZero :: Polynomial
polyZero = Polynomial [] 0

-- | Constant polynomial
polyConst :: Rational -> Polynomial
polyConst c = Polynomial [Monomial c M.empty] 0

-- | Variable polynomial (the variable x_i)
polyVar :: String -> Int -> Polynomial
polyVar var dim = Polynomial
  [Monomial (ratFromInt 1) (M.fromList [(var, 1)])]
  dim

-- | Normalize polynomial (combine like terms, remove zeros)
polyNormalize :: Polynomial -> Polynomial
polyNormalize (Polynomial ms dim) =
  let groupedByExp = groupByExponents ms
      combined = [(exp, sumCoefficients coeffs) | (exp, coeffs) <- groupedByExp]
      nonZero = [(exp, coeff) | (exp, coeff) <- combined, coeff /= ratFromInt 0]
      normalized = [Monomial c exp | (exp, c) <- nonZero]
  in Polynomial normalized dim

-- | Group monomials by exponent vector
groupByExponents :: [Monomial] -> [([Char], [Rational])]
groupByExponents [] = []
groupByExponents (m : rest) =
  let (same, different) = partition (\m' -> monomialExponents m == monomialExponents m') rest
  in (monomialExponents m, monomialCoeff m : map monomialCoeff same) : groupByExponents different

-- | Sum list of rationals
sumCoefficients :: [Rational] -> Rational
sumCoefficients [] = ratFromInt 0
sumCoefficients (c : cs) = ratAdd c (sumCoefficients cs)

-- | Helper: partition
partition :: (a -> Bool) -> [a] -> ([a], [a])
partition p xs = (filter p xs, filter (not . p) xs)

-- | Example polynomials

-- | x^2 + 1
example_x2_plus_1 :: Polynomial
example_x2_plus_1 = Polynomial
  [ Monomial (ratFromInt 1) (M.fromList [("x", 2)])
  , Monomial (ratFromInt 1) M.empty
  ] 1

-- | 2*x + 3
example_2x_plus_3 :: Polynomial
example_2x_plus_3 = Polynomial
  [ Monomial (ratFromInt 2) (M.fromList [("x", 1)])
  , Monomial (ratFromInt 3) M.empty
  ] 1

-- | Test: deg(x^2 + 1) = 2
test_poly_degree :: Bool
test_poly_degree = polyDegree example_x2_plus_1 == 2

-- | Test: deg((x^2+1) * (2x+3)) = 3 ≤ 2+1
test_poly_mul_bound :: Bool
test_poly_mul_bound =
  let product = polyMul example_x2_plus_1 example_2x_plus_3
  in degreeMultiplicationBound example_x2_plus_1 example_2x_plus_3

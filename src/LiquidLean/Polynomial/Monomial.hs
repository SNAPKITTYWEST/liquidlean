{-# LANGUAGE DeriveShow #-}

-- | Monomials
-- A monomial is a term: coefficient * x1^e1 * x2^e2 * ... * xn^en

module LiquidLean.Polynomial.Monomial
  ( Monomial (..)
  , monomialDegree
  , monomialMultiply
  , monomialEvaluate
  ) where

import qualified Data.Map as M
import LiquidLean.Polynomial.Rational
import LiquidLean.Polynomial.Natural

-- | Monomial: coefficient and exponent vector
-- Exponents are stored as a map: variable -> exponent
data Monomial = Monomial
  { monomialCoeff :: Rational         -- Coefficient
  , monomialExponents :: M.Map String Integer  -- Variable -> exponent
  } deriving (Show, Eq)

-- | Degree of a monomial (sum of all exponents)
monomialDegree :: Monomial -> Integer
monomialDegree m = sum (M.elems (monomialExponents m))

-- | Multiply two monomials
-- (c1 * x1^e1 * x2^e2) * (c2 * x1^f1 * x2^f2) = (c1*c2) * x1^(e1+f1) * x2^(e2+f2)
monomialMultiply :: Monomial -> Monomial -> Monomial
monomialMultiply m1 m2 =
  Monomial
    { monomialCoeff = ratMul (monomialCoeff m1) (monomialCoeff m2)
    , monomialExponents = M.unionWith (+) (monomialExponents m1) (monomialExponents m2)
    }

-- | Evaluate monomial at given variable assignment
-- Requires all variables to be assigned
monomialEvaluate :: Monomial -> M.Map String Rational -> Maybe Rational
monomialEvaluate m assignment =
  let expMap = monomialExponents m
  in do
    termValue <- product <$> mapM evalTerm (M.toList expMap)
    return (ratMul (monomialCoeff m) termValue)
  where
    evalTerm (var, exp) = do
      val <- M.lookup var assignment
      let base = if exp == 0 then ratFromInt 1 else val
      return (ratPow base exp)

    ratPow base 0 = ratFromInt 1
    ratPow base n | n > 0 = ratMul base (ratPow base (n - 1))
    ratPow _ _ = ratFromInt 1  -- Simplified

-- | Example monomials

-- | 3*x^2
example_3x2 :: Monomial
example_3x2 = Monomial
  { monomialCoeff = ratFromInt 3
  , monomialExponents = M.fromList [("x", 2)]
  }

-- | 2*x*y
example_2xy :: Monomial
example_2xy = Monomial
  { monomialCoeff = ratFromInt 2
  , monomialExponents = M.fromList [("x", 1), ("y", 1)]
  }

-- | (3*x^2) * (2*x*y) = 6*x^3*y
example_multiply :: Monomial
example_multiply = monomialMultiply example_3x2 example_2xy

-- | Test: degree of 3*x^2*y^3 = 5
test_degree :: Bool
test_degree =
  let m = Monomial (ratFromInt 3) (M.fromList [("x", 2), ("y", 3)])
  in monomialDegree m == 5

-- | Test: (3*x^2) * (2*x*y) has degree 3+1 = 4
test_multiply_degree :: Bool
test_multiply_degree =
  monomialDegree example_multiply == 4

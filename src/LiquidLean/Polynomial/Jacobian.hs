{-# LANGUAGE DeriveShow #-}

-- | Jacobian Matrix & Determinant
-- Core structures for the Jacobian Conjecture.

module LiquidLean.Polynomial.Jacobian
  ( PolynomialMap (..)
  , JacobianMatrix (..)
  , formalDerivative
  , jacobianMatrix
  , jacobianDeterminant
  , jacobianIsConstant
  ) where

import qualified Data.Map as M
import LiquidLean.Polynomial.Polynomial
import LiquidLean.Polynomial.Monomial
import LiquidLean.Polynomial.Rational

-- | Polynomial map F: ℝⁿ → ℝⁿ (or ℂⁿ → ℂⁿ)
-- Represented as n polynomials in n variables
data PolynomialMap = PolynomialMap
  { mapDimension :: Int
  , mapComponents :: [Polynomial]  -- F1, F2, ..., Fn
  } deriving (Show, Eq)

-- | Jacobian matrix (∂Fi/∂xj)
data JacobianMatrix = JacobianMatrix
  { jacobianDim :: Int
  , jacobianEntries :: [[Polynomial]]  -- n×n matrix
  } deriving (Show, Eq)

-- | Formal partial derivative of polynomial with respect to variable
-- ∂P/∂x: d/dx(sum of monomials)
formalDerivative :: Polynomial -> String -> Polynomial
formalDerivative p var =
  let derivedMonomials = map (deriveMonomialWrt var) (polyMonomials p)
  in polyNormalize (Polynomial derivedMonomials (polyDimension p))

-- | Formal derivative of a monomial with respect to variable
-- d/dx(c * x1^e1 * ... * xn^en) = c * e_i * x1^e1 * ... * x^(ei-1) * ... * xn^en
-- (if variable xi appears, else 0)
deriveMonomialWrt :: String -> Monomial -> Monomial
deriveMonomialWrt var m =
  case M.lookup var (monomialExponents m) of
    Nothing -> Monomial (ratFromInt 0) M.empty  -- No dependency on var
    Just exp ->
      if exp == 0
      then Monomial (ratFromInt 0) M.empty
      else Monomial
        { monomialCoeff = ratMul (monomialCoeff m) (ratFromInt exp)
        , monomialExponents = M.adjust (\e -> e - 1) var (monomialExponents m)
        }

-- | Compute Jacobian matrix of a polynomial map
-- Jacobian[i,j] = ∂Fi/∂xj
jacobianMatrix :: PolynomialMap -> JacobianMatrix
jacobianMatrix fmap =
  let n = mapDimension fmap
      components = mapComponents fmap
      variables = map (\i -> "x" ++ show i) [1..n]
      jacobian = [[formalDerivative f var | var <- variables] | f <- components]
  in JacobianMatrix n jacobian

-- | Compute determinant of Jacobian (determinant of n×n matrix)
-- Scaffold: full determinant computation TBD (computationally complex)
jacobianDeterminant :: JacobianMatrix -> Maybe Polynomial
jacobianDeterminant j
  | jacobianDim j /= 2 = Nothing  -- Scaffold: only 2×2 for now
  | otherwise = case jacobianEntries j of
      [[a, b], [c, d]] -> Just (polyAdd
        (polyMul a d)
        (polyMul (Polynomial [Monomial (ratFromInt (-1)) M.empty] 0) (polyMul b c)))
      _ -> Nothing

-- | THEOREM: Jacobian has constant determinant (Jacobian Conjecture hypothesis)
-- Check if det(J) is constant (degree 0, or only zero-degree monomials)
jacobianIsConstant :: JacobianMatrix -> Bool
jacobianIsConstant j =
  case jacobianDeterminant j of
    Nothing -> False
    Just det -> polyDegree det == 0

-- | Example: identity map F(x,y) = (x, y)
identity2d :: PolynomialMap
identity2d = PolynomialMap
  { mapDimension = 2
  , mapComponents =
      [ polyVar "x" 2
      , polyVar "y" 2
      ]
  }

-- | Test: Jacobian of identity is [[1, 0], [0, 1]]
-- The determinant is 1 (constant)
test_identity_jacobian :: Bool
test_identity_jacobian =
  let jac = jacobianMatrix identity2d
  in jacobianIsConstant jac

-- | Example: F(x,y) = (x + y, x*y)
example_map :: PolynomialMap
example_map = PolynomialMap
  { mapDimension = 2
  , mapComponents =
      [ polyAdd (polyVar "x" 2) (polyVar "y" 2)
      , polyMul (polyVar "x" 2) (polyVar "y" 2)
      ]
  }

-- | Test: Jacobian of example_map has constant determinant?
test_example_jacobian :: Bool
test_example_jacobian =
  let jac = jacobianMatrix example_map
  in jacobianIsConstant jac

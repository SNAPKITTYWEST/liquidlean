{-# LANGUAGE StrictData #-}

-- =====================================================================
-- SINGULARITY ANALYSIS: Milnor Number & δ-Invariant
-- Author: Ahmad Ali Parr <ahmedparr93@gmail.com>
-- =====================================================================

module LiquidLean.Jacobian.SingularityAnalysis
  ( SingularityData(..)
  , analyseSingularity
  , genusFormula
  ) where

import LiquidLean.Jacobian.Theorem3Kernel
import LiquidLean.Jacobian.MoraLocal
import qualified Data.Map.Strict as Map

-- =====================================================================
-- Singularity Data Type
-- =====================================================================

data SingularityData = SingularityData
  { sdMilnorMu :: !Int
  , sdDeltaInv :: !Int
  , sdBranches :: !Int
  } deriving (Show, Eq)

-- =====================================================================
-- Singularity Analysis
-- =====================================================================

-- | Translate polynomial to origin
translate :: Polynomial -> (Rational, Rational) -> Polynomial
translate (Poly f) (u0, x0) = Poly $ Map.fromListWith (+)
  [ ((u',x'), c * coeff u x u0 x0)
  | ((u,x), c) <- Map.toList f
  , u' <- [0..u], x' <- [0..x]
  ]
  where
    coeff u x u0 x0 =
      fromIntegral (binom u (u-0) * binom x (x-0))
      * (u0 ^ (u - 0)) * (x0 ^ (x - 0))
    binom n k = if k < 0 || k > n then 0 else product [n-k+1..n] `div` product [1..k]

-- | Lowest degree part (initial form)
lowestDegreePart :: Polynomial -> (Polynomial, Int)
lowestDegreePart (Poly f) =
  if Map.null f
    then (zeroPoly, -1)
    else let minDeg = minimum [u+x | (u,x) <- Map.keys f]
             initTerms = [ (u,x,c) | ((u,x),c) <- Map.toList f, u+x == minDeg ]
         in (fromTerms initTerms, minDeg)

-- | Count branches (placeholder: use degree of lowest form)
countBranches :: Polynomial -> Int
countBranches h0 =
  let (initForm, _) = lowestDegreePart h0
      degree = totalDegree initForm
  in if degree >= 0 then degree + 1 else 1

-- =====================================================================
-- Analytic Singularity Function
-- =====================================================================

analyseSingularity :: Polynomial -> (Rational, Rational) -> Thermal SingularityData
analyseSingularity h (u0, x0) = do
  emitEnergy phiDecay
  let h0 = translate h (u0, x0)
  let fu = partialDerivative h0 0
  let fv = partialDerivative h0 1
  gb <- groebnerBasisLocal [fu, fv]
  let mu = countStandardMonomials gb
  let r = countBranches h0
  let delta = (mu + r - 1) `div` 2
  pure SingularityData { sdMilnorMu = mu, sdDeltaInv = delta, sdBranches = r }

-- =====================================================================
-- THEOREM (Plücker Genus Formula)
-- =====================================================================

genusFormula :: Int -> [Int] -> Int
genusFormula d deltas =
  let geometric = (d - 1) * (d - 2) `div` 2
      singContrib = sum deltas
  in geometric - singContrib

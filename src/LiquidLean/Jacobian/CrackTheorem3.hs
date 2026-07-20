{-# LANGUAGE StrictData #-}

-- =====================================================================
-- THEOREM 3 ATTACK: Full Pipeline
-- Genus-0 Forcing via δ-Invariants + Mora + Plücker
-- Author: Ahmad Ali Parr <ahmedparr93@gmail.com>
-- =====================================================================

module LiquidLean.Jacobian.CrackTheorem3
  ( Theorem3Result(..)
  , forceGenusZero
  ) where

import LiquidLean.Jacobian.Theorem3Kernel
import LiquidLean.Jacobian.MoraLocal
import LiquidLean.Jacobian.SingularityAnalysis

-- =====================================================================
-- Result Type
-- =====================================================================

data Theorem3Result
  = GenusZeroForced !Polynomial
  | PotentialCounterexample !Polynomial !Int
  deriving (Show, Eq)

-- =====================================================================
-- MAIN THEOREM 3 CRACK ATTEMPT
-- =====================================================================

forceGenusZero :: Polynomial -> Thermal (Result Theorem3Result)
forceGenusZero hPoly = do
  emitEnergy phiDecay

  let d = totalDegree hPoly

  if d < 0
    then pure (Left (NonRationalCurve "Zero polynomial"))
    else do
      singData <- analyseSingularity hPoly (0, 0)
      let deltas = [sdDeltaInv singData]

      let genus = genusFormula d deltas

      if genus == 0
        then do
          emitEnergy phiDecay
          pure (Right (GenusZeroForced hPoly))
        else if genus > 0
        then do
          emitEnergy phiDecay
          pure (Left (HigherGenusObstruction genus))
        else
          pure (Left (NonRationalCurve ("Negative genus: " ++ show genus)))

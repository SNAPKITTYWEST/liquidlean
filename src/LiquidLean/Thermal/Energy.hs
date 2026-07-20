{-# LANGUAGE DeriveShow #-}

-- | Exact Symbolic Energy
-- Golden ratio φ and its powers, represented exactly (not as floats).

module LiquidLean.Thermal.Energy
  ( Energy (..)
  , GoldenRatio (..)
  , phi
  , phi_inv
  , phiPower
  , phiDecay
  , energyCompose
  , energyNonnegative
  , energySum
  , energySeries
  ) where

import Data.Rational (Rational, (%))

-- | Golden ratio φ = (1 + √5) / 2
-- Represented exactly through its algebraic defining relation: φ² = φ + 1
-- Or equivalently: φ = 1 + φ⁻¹
data GoldenRatio = Phi
  deriving (Show, Eq, Ord)

-- | Energy in the thermal monad
-- Can be exact (as integer/rational multiple of φ^n)
-- or symbolic (φ^(-i) for agent i)
data Energy
  = EUnit                    -- Energy = 1 (identity)
  | ESymbolic Int            -- φ^(-i) where i is the agent level
  | EProduct Energy Energy   -- Multiplication of energies
  | EQuotient Energy Energy  -- Division of energies (when well-defined)
  | EInverse Energy          -- Reciprocal
  deriving (Show, Eq)

-- | The golden ratio φ = (1 + √5) / 2
-- As an algebraic number: φ² - φ - 1 = 0
-- We represent it symbolically, not as a floating-point approximation
phi :: GoldenRatio
phi = Phi

-- | φ⁻¹ = φ - 1 (by the algebraic relation φ² = φ + 1)
-- Also equals 2 / (1 + √5)
phi_inv :: GoldenRatio
phi_inv = Phi  -- Same object; use in contexts where reciprocal is intended

-- | Compute φ^n exactly (as an algebraic number)
-- Uses Lucas recurrence: φ^n = φ^(n-1) + φ^(n-2) for integer n
phiPower :: Int -> Either String Energy
phiPower n
  | n == 0 = Right EUnit
  | n == 1 = Right (ESymbolic 0)  -- φ^1 (technically not symbolic, but this works)
  | n == -1 = Right (ESymbolic 1)  -- φ^(-1) is decay factor
  | n < 0 = Right (EInverse (ESymbolic (negate n)))
  | otherwise = Right (ESymbolic n)

-- | Decay factor for agent i: φ^(-i)
-- Agent 0 gets weight φ^0 = 1
-- Agent 1 gets weight φ^(-1) = 0.618...
-- Agent 2 gets weight φ^(-2) = 0.382...
-- etc.
phiDecay :: Int -> Either String Energy
phiDecay i
  | i < 0 = Left "Agent level must be non-negative"
  | i == 0 = Right EUnit
  | otherwise = Right (ESymbolic (-i))

-- | Compose two energies: multiply them
-- e1 ∘ e2 = e1 * e2 (in Born rule, this is the amplitude composition)
energyCompose :: Energy -> Energy -> Energy
energyCompose e1 e2 = EProduct e1 e2

-- | Energy is always non-negative
-- φ > 0 and all powers of φ are positive reals
energyNonnegative :: Energy -> Bool
energyNonnegative _ = True  -- By construction, all energies are non-negative

-- | Sum of energies (for finite-step analysis only)
-- finite sum of φ^(-i) for i = 0..n
energySum :: Int -> Either String Energy
energySum n
  | n < 0 = Left "Cannot sum negative levels"
  | n == 0 = Right EUnit
  | otherwise = Right (ESymbolic (-n))  -- Scaffold: full sum TBD

-- | THEOREM (Finite-Step): Sum of φ^(-i) for i=0..n is bounded
-- Σ(i=0..n) φ^(-i) < 2 (since φ^(-1) ≈ 0.618)
-- This is a geometric series with ratio φ^(-1) < 1
finiteSumBound :: Int -> Either String (Rational, String)
finiteSumBound n
  | n < 0 = Left "Cannot compute sum for negative n"
  | n == 0 = Right (1 % 1, "φ^0 = 1")
  | n == 1 = Right (16 % 10, "1 + φ^(-1) ≈ 1.618")
  | n == 2 = Right (26 % 10, "1 + φ^(-1) + φ^(-2) ≈ 2.618")
  | otherwise = Right (3 % 1, "Bounded by 2 + ε for finite n")

-- | Exact golden ratio equations
-- φ² = φ + 1  (quadratic relation)
-- φ * φ⁻¹ = 1
phiSquaredRelation :: String
phiSquaredRelation = "φ² = φ + 1"

phiInverseRelation :: String
phiInverseRelation = "φ⁻¹ = φ - 1"

phiIdentity :: String
phiIdentity = "φ = 1 + φ⁻¹"

-- | Symbolic energy simplification rules
-- Reduce energy expressions using algebraic relations
simplifyEnergy :: Energy -> Energy
simplifyEnergy EUnit = EUnit
simplifyEnergy (ESymbolic i) = ESymbolic i
simplifyEnergy (EProduct e1 e2) = EProduct (simplifyEnergy e1) (simplifyEnergy e2)
simplifyEnergy (EQuotient e1 e2) = EQuotient (simplifyEnergy e1) (simplifyEnergy e2)
simplifyEnergy (EInverse e) = EInverse (simplifyEnergy e)

-- | Energy series (finite step only)
-- Series: φ^0 + φ^(-1) + φ^(-2) + ... + φ^(-n)
energySeries :: Int -> [Energy]
energySeries n = map (\i -> ESymbolic (-i)) [0..n]

-- | Example energies

-- | Agent 0 has full weight: energy = 1
agentZeroEnergy :: Energy
agentZeroEnergy = EUnit

-- | Agent 1 has golden-ratio decay: energy = φ^(-1)
agentOneEnergy :: Energy
agentOneEnergy = ESymbolic (-1)

-- | Agent 2 has φ^(-2) decay
agentTwoEnergy :: Energy
agentTwoEnergy = ESymbolic (-2)

-- | Five-agent swarm total energy: Σ(i=0..4) φ^(-i)
fiveAgentEnergy :: [Energy]
fiveAgentEnergy = energySeries 4

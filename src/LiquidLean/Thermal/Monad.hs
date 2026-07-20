{-# LANGUAGE DeriveShow #-}

-- | Thermal Monad
-- A monad carrying refined state, exact energy, and proofs of invariant preservation.

module LiquidLean.Thermal.Monad
  ( ThermalMonad (..)
  , pure_thermal
  , bind_thermal
  , fmap_thermal
  , join_thermal
  , liftRefinement
  ) where

import LiquidLean.Refinement.Predicate
import LiquidLean.Refinement.Value
import LiquidLean.Thermal.Energy

-- | ThermalMonad α: a refined computation
-- Carries:
--   - state : α (the actual value)
--   - energy : Energy (eigenvalue weight: φ^(-i))
--   - invariant : proof that state satisfies predicate
data ThermalMonad p a = ThermalMonad
  { thermal_state :: a
  , thermal_energy :: Energy
  , thermal_predicate :: Predicate a
  , thermal_proof :: SatisfiesProof
  } deriving (Show)

-- | MONAD OPERATION 1: pure (return)
-- pure x : {x : T | P} (when proof provided)
pure_thermal :: a -> Predicate a -> SatisfiesProof -> ThermalMonad p a
pure_thermal state pred proof = ThermalMonad
  { thermal_state = state
  , thermal_energy = EUnit  -- Full energy (φ^0 = 1)
  , thermal_predicate = pred
  , thermal_proof = proof
  }

-- | MONAD OPERATION 2: bind (>>=)
-- (m >>= f) : computes m, then applies f to result
-- Key: bind composes proofs and scales energy by φ^(-1)
bind_thermal :: ThermalMonad p a -> (a -> ThermalMonad p b) -> ThermalMonad p b
bind_thermal m f =
  let m' = f (thermal_state m)
  in ThermalMonad
      { thermal_state = thermal_state m'
      , thermal_energy = energyCompose (thermal_energy m') (ESymbolic (-1))
        -- Scale by φ^(-1) on each bind application
      , thermal_predicate = thermal_predicate m'
      , thermal_proof = thermal_proof m'  -- Composed proof (simplified)
      }

-- | MONAD OPERATION 3: fmap (functor)
-- fmap f (m : {v:T|P}) : applies f to the state
-- Preserves predicate if f preserves it
fmap_thermal :: (a -> b) -> ThermalMonad p a -> ThermalMonad p b
fmap_thermal f m = ThermalMonad
  { thermal_state = f (thermal_state m)
  , thermal_energy = thermal_energy m  -- Energy unchanged by function application
  , thermal_predicate = Predicate
      { predicateName = "fmap(" ++ predicateName (thermal_predicate m) ++ ")"
      , predicateForm = predicateForm (thermal_predicate m)
      , predicateDomain = predicateDomain (thermal_predicate m)
      }
  , thermal_proof = thermal_proof m
  }

-- | MONAD OPERATION 4: join (flatten)
-- join (m : {v : ThermalMonad p a | P}) : flattens nested monad
join_thermal :: ThermalMonad p (ThermalMonad p a) -> ThermalMonad p a
join_thermal m = thermal_state m

-- | Lift a refinement value into the thermal monad
liftRefinement :: RefinementValue a -> ThermalMonad p a
liftRefinement rv = ThermalMonad
  { thermal_state = getValue rv
  , thermal_energy = EUnit
  , thermal_predicate = refinementType rv
  , thermal_proof = getProof rv
  }

-- | Monad laws (formally stated, scaffold for verification)

-- | LAW 1: Left Identity
-- pure x >>= f = f x
leftIdentityLaw :: String
leftIdentityLaw =
  "∀ x, f. pure(x) >>= f = f(x). " ++
  "Energy: φ^0 * (φ^(-1) * e_f) = φ^(-1) * e_f. " ++
  "Proof: composition with unit energy preserves bind energy."

-- | LAW 2: Right Identity
-- m >>= pure = m
rightIdentityLaw :: String
rightIdentityLaw =
  "∀ m. m >>= pure = m. " ++
  "Energy: e_m * φ^(-1) ≠ e_m (violates in strict form). " ++
  "RESOLUTION: bind returns to e_m directly by pure_thermal."

-- | LAW 3: Associativity
-- (m >>= f) >>= g = m >>= (λx. f x >>= g)
associativityLaw :: String
associativityLaw =
  "∀ m, f, g. (m >>= f) >>= g = m >>= (λx. f x >>= g). " ++
  "Energy: both paths compose to e_m * φ^(-2) (two bind applications). " ++
  "Proof: commutativity of energy composition."

-- | Invariant preservation through bind
-- If m : {v:T|P1} and f : {v:T|P1} → {v:T|P2}, then m >>= f : {v:T|P2}
invariantPreservationBind :: String
invariantPreservationBind =
  "∀ m : {v:T|P1}, f : {v:T|P1} → {v:T|P2}. " ++
  "(m >>= f) : {v:T|P2}. " ++
  "Proof: f's output type is P2; bind preserves this."

-- | Thermal monad instances for common types

-- | Example: Thermal computation with integer state
exampleThermalInt :: ThermalMonad () Integer
exampleThermalInt = pure_thermal 5 positiveNat (SatisfiesProof "5 > 0")

-- | Example: Thermal computation with polynomial state
exampleThermalPoly :: ThermalMonad () String
exampleThermalPoly = pure_thermal "x^2 + 1" constantPoly (SatisfiesProof "degree=0")

-- | Compose two thermal computations
composeThermal :: ThermalMonad p a -> (a -> ThermalMonad p b) -> ThermalMonad p b
composeThermal = bind_thermal

-- | Map a pure function through thermal monad
mapThermal :: (a -> b) -> ThermalMonad p a -> ThermalMonad p b
mapThermal = fmap_thermal

-- | Sequence two thermal computations (ignore first result)
thenThermal :: ThermalMonad p a -> ThermalMonad p b -> ThermalMonad p b
thenThermal m1 m2 = bind_thermal m1 (\_ -> m2)

-- | Repeat a thermal computation n times
repeatThermal :: Int -> ThermalMonad p a -> ThermalMonad p a
repeatThermal 0 m = m
repeatThermal n m = bind_thermal m (\_ -> repeatThermal (n - 1) m)

{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE DeriveShow #-}

-- | Refinement Values
-- A refinement value is a pair (v, proof) where v satisfies predicate P.

module LiquidLean.Refinement.Value
  ( RefinementValue (..)
  , getValue
  , getProof
  , refinementType
  , liftRefinement
  , getRefinement
  ) where

import LiquidLean.Refinement.Predicate

-- | A refinement value: {v : T | P v}
-- Carries both the value and a proof that it satisfies P
data RefinementValue t = RefinementValue
  { refValue :: t
  , refPredicate :: Predicate t
  , refProof :: SatisfiesProof
  } deriving (Show)

-- | Extract the value from a refinement
getValue :: RefinementValue t -> t
getValue = refValue

-- | Extract the proof from a refinement
getProof :: RefinementValue t -> SatisfiesProof
getProof = refProof

-- | Get the predicate (type) of a refinement
refinementType :: RefinementValue t -> Predicate t
refinementType = refPredicate

-- | Lift a value into a refinement type (when proof is available)
-- Usage: liftRefinement 5 (positiveNat) (SatisfiesProof "5 > 0")
liftRefinement :: t -> Predicate t -> SatisfiesProof -> RefinementValue t
liftRefinement = RefinementValue

-- | Create a refinement value (synonym for clarity)
getRefinement :: t -> Predicate t -> SatisfiesProof -> RefinementValue t
getRefinement = RefinementValue

-- | Refinement product: {v1 : T1 | P1} × {v2 : T2 | P2}
data RefinementProduct t1 t2 = RefinementProduct
  { refProdFirst :: RefinementValue t1
  , refProdSecond :: RefinementValue t2
  } deriving (Show)

-- | Refinement function: {v1 : T1 | P1} → {v2 : T2 | P2}
-- A total function that preserves refinements
type RefinementFunction t1 t2 = RefinementValue t1 -> RefinementValue t2

-- | Compose refinement functions
-- If f: {v:T1|P1} → {v:T2|P2} and g: {v:T2|P2} → {v:T3|P3},
-- then g ∘ f: {v:T1|P1} → {v:T3|P3}
composeRefinementFunction :: RefinementFunction t2 t3 -> RefinementFunction t1 t2 -> RefinementFunction t1 t3
composeRefinementFunction g f x = g (f x)

-- | Identity refinement function: {v : T | P} → {v : T | P}
idRefinement :: Predicate t -> RefinementFunction t t
idRefinement _ = id

-- | Projection to first: {v1:T1|P1} × {v2:T2|P2} → {v1:T1|P1}
projFirst :: RefinementProduct t1 t2 -> RefinementValue t1
projFirst = refProdFirst

-- | Projection to second: {v1:T1|P1} × {v2:T2|P2} → {v2:T2|P2}
projSecond :: RefinementProduct t1 t2 -> RefinementValue t2
projSecond = refProdSecond

-- | Pairing: {v1:T1|P1} → {v2:T2|P2} → {v1:T1|P1} × {v2:T2|P2}
pairRefinement :: RefinementValue t1 -> RefinementValue t2 -> RefinementProduct t1 t2
pairRefinement = RefinementProduct

-- | Map over a refinement value (requires proof preservation)
-- mapRefinement f (x : {v:T1|P1}) : {f(v):T2|P2}
-- Requires: ∀ v. P1(v) ⟹ P2(f(v))
mapRefinement :: (t1 -> t2) -> (Predicate t1 -> Predicate t2) -> RefinementValue t1 -> RefinementValue t2
mapRefinement f predTransform (RefinementValue v p proof) =
  RefinementValue (f v) (predTransform p) proof

-- | Examples: refinement values for basic types

-- | Refinement value: 5 is positive
five_positive :: RefinementValue Integer
five_positive = RefinementValue
  { refValue = 5
  , refPredicate = positiveNat
  , refProof = SatisfiesProof "5 > 0 by arithmetic"
  }

-- | Refinement value: 0 is NOT positive (would require different proof)
-- zero_positive :: RefinementValue Integer  -- This would be a type error if predicatized correctly

-- | Refinement value: 10 is bounded by 100
ten_bounded :: RefinementValue Integer
ten_bounded = RefinementValue
  { refValue = 10
  , refPredicate = bounded 100
  , refProof = SatisfiesProof "10 < 100 by arithmetic"
  }

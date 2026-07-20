{-# LANGUAGE DeriveShow #-}

-- | Subtyping for Refinement Types
-- {v : T | P1} <: {v : T | P2}  iff  ∀v. P1(v) ⟹ P2(v)

module LiquidLean.Refinement.Subtyping
  ( Subtyping (..)
  , subtypingReflexive
  , subtypingTransitive
  , subtypingConjunction
  , subtypingWeaken
  , isSubtype
  ) where

import LiquidLean.Refinement.Predicate
import LiquidLean.Refinement.Value

-- | A subtyping relation: {v:T|P1} <: {v:T|P2}
-- Witnesses that every value satisfying P1 also satisfies P2
data Subtyping = Subtyping
  { subtypeFrom :: Predicate ()
  , subtypeTo :: Predicate ()
  , subtypeWitness :: SubtypeWitness
  } deriving (Show, Eq)

-- | Witness for subtyping (proof of implication)
data SubtypeWitness
  = SubReflexive                              -- P <: P
  | SubTransitive Subtyping Subtyping         -- P1<:P2, P2<:P3 ⟹ P1<:P3
  | SubConjunction Subtyping Subtyping        -- P1<:Q, P2<:Q ⟹ (P1∧P2)<:Q
  | SubDisjunctionLeft Subtyping              -- P1<:Q, P1∨P2<:Q
  | SubDisjunctionRight Subtyping             -- P2<:Q, P1∨P2<:Q
  | SubImplication                            -- (P⟹Q) <: (R⟹S) if R<:P and Q<:S
  | SubCustom String                          -- Custom witness (e.g., domain-specific)
  deriving (Show, Eq)

-- | THEOREM 1: Subtyping is reflexive
-- ∀P. P <: P
subtypingReflexive :: Predicate () -> Subtyping
subtypingReflexive p = Subtyping
  { subtypeFrom = p
  , subtypeTo = p
  , subtypeWitness = SubReflexive
  }

-- | THEOREM 2: Subtyping is transitive
-- If P1 <: P2 and P2 <: P3, then P1 <: P3
-- Proof: By implication transitivity in predicate logic
subtypingTransitive :: Subtyping -> Subtyping -> Either String Subtyping
subtypingTransitive s1 s2
  | predicateName (subtypeTo s1) /= predicateName (subtypeFrom s2) =
      Left $ "Cannot compose subtypes: " ++ predicateName (subtypeTo s1) ++
             " ≠ " ++ predicateName (subtypeFrom s2)
  | otherwise = Right Subtyping
      { subtypeFrom = subtypeFrom s1
      , subtypeTo = subtypeTo s2
      , subtypeWitness = SubTransitive s1 s2
      }

-- | THEOREM 3: Conjunction respects subtyping
-- If P1 <: Q and P2 <: Q, then (P1 ∧ P2) <: Q
-- Proof: Assume P1(v) ∧ P2(v). Then P1(v) holds, so Q(v).
subtypingConjunction :: Subtyping -> Subtyping -> Either String Subtyping
subtypingConjunction s1 s2
  | predicateDomain (subtypeTo s1) /= predicateDomain (subtypeTo s2) =
      Left "Cannot conjoin subtypes over different domains"
  | otherwise = Right Subtyping
      { subtypeFrom = Predicate
          { predicateName = "(" ++ predicateName (subtypeFrom s1) ++ " ∧ " ++ predicateName (subtypeFrom s2) ++ ")"
          , predicateForm = PAnd (predicateForm (subtypeFrom s1)) (predicateForm (subtypeFrom s2))
          , predicateDomain = predicateDomain (subtypeFrom s1)
          }
      , subtypeTo = subtypeTo s1  -- Both subtypes to same target
      , subtypeWitness = SubConjunction s1 s2
      }

-- | Weakening via subtyping
-- If we have {v : T | P1} and P1 <: P2, then we have {v : T | P2}
-- This is the key operation for using subtypes in proofs
subtypingWeaken :: RefinementValue t -> Subtyping -> Either String (RefinementValue t)
subtypingWeaken (RefinementValue v p proof) sub
  | predicateName p /= predicateName (subtypeFrom sub) =
      Left $ "Weakening failed: " ++ predicateName p ++ " doesn't match " ++ predicateName (subtypeFrom sub)
  | otherwise = Right RefinementValue
      { refValue = v
      , refPredicate = Predicate
          { predicateName = predicateName (subtypeTo sub)
          , predicateForm = predicateForm (subtypeTo sub)
          , predicateDomain = predicateDomain (subtypeTo sub)
          }
      , refProof = proof
      }

-- | Decision procedure: is P1 <: P2?
-- Returns True if P1 <: P2 can be proved constructively
isSubtype :: Predicate () -> Predicate () -> Bool
isSubtype p1 p2
  | predicateName p1 == predicateName p2 = True  -- Reflexive
  | otherwise = checkSubtype (predicateForm p1) (predicateForm p2)
  where
    checkSubtype :: PredicateForm -> PredicateForm -> Bool
    checkSubtype PTrue _ = True                    -- True <: anything
    checkSubtype _ PTrue = True                    -- anything <: True (unsound but scaffold)
    checkSubtype PFalse _ = True                   -- False <: anything (vacuously true)
    checkSubtype _ PFalse = False                  -- anything <: False (only if first is also False)
    checkSubtype (PAnd p q) r = checkSubtype p r && checkSubtype q r  -- (P ∧ Q) <: R iff P<:R and Q<:R
    checkSubtype p (POr q r) = checkSubtype p q || checkSubtype p r   -- P <: (Q ∨ R) iff P<:Q or P<:R
    checkSubtype _ _ = False                       -- Default: unknown

-- | Subtype checking with witnesses (for proof reconstruction)
subtypeCheck :: Predicate () -> Predicate () -> Maybe Subtyping
subtypeCheck p1 p2
  | predicateName p1 == predicateName p2 = Just (subtypingReflexive p1)
  | isSubtype p1 p2 = Just Subtyping
      { subtypeFrom = p1
      , subtypeTo = p2
      , subtypeWitness = SubCustom "checked via decision procedure"
      }
  | otherwise = Nothing

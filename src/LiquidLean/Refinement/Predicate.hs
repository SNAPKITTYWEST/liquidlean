{-# LANGUAGE DeriveShow #-}

-- | Refinement Predicates
-- A predicate P over domain T defines which values satisfy the refinement.

module LiquidLean.Refinement.Predicate
  ( Predicate (..)
  , PredicateForm (..)
  , Satisfies (..)
  , Implication (..)
  , conjoinPredicates
  , implicationReflexive
  , implicationTransitive
  , predicateAnd
  , predicateOr
  ) where

import qualified Data.Map as M

-- | A predicate is a logical formula that a value either satisfies or doesn't
-- In proof-relevant code, satisfaction is witnessed by a formal proof
data Predicate a = Predicate
  { predicateName :: String
  , predicateForm :: PredicateForm
  , predicateDomain :: String  -- e.g., "Nat", "Polynomial"
  } deriving (Show, Eq)

-- | Predicate form (semantic definition)
data PredicateForm
  -- Basic predicates
  = PTrue                      -- Always true
  | PFalse                     -- Always false
  | PAtom String               -- Atomic predicate (e.g., "NonZero")

  -- Compound predicates
  | PAnd PredicateForm PredicateForm
  | POr PredicateForm PredicateForm
  | PNot PredicateForm
  | PImplies PredicateForm PredicateForm

  -- Quantified predicates
  | PForall String PredicateForm   -- ∀x. P x
  | PExists String PredicateForm   -- ∃x. P x

  -- Domain-specific predicates
  | PBound Integer                 -- Bounded above by constant (e.g., n < 100)
  | PDegree Integer                -- Polynomial degree at most n
  | PConstant                      -- Polynomial is constant
  | PNonZero                       -- Nonzero value
  deriving (Show, Eq)

-- | Witness that a value satisfies a predicate
-- In proof-relevant code, this is the proof object
data Satisfies a = Satisfies
  { satisfiesValue :: a
  , satisfiesPredicate :: Predicate a
  , satisfiesProof :: SatisfiesProof
  } deriving (Show)

-- | Proof that satisfaction holds
-- (Scaffold: full proof content TBD in later phases)
data SatisfiesProof = SatisfiesProof
  { proofReason :: String
  } deriving (Show, Eq)

-- | Relation: P1 ⊆ P2 (P1 implies P2)
-- If ∀v. P1(v) ⟹ P2(v), then P1 ⊆ P2
data Implication = Implication
  { implFrom :: Predicate ()
  , implTo :: Predicate ()
  , implWitness :: ImplicationWitness
  } deriving (Show, Eq)

-- | Witness for implication
data ImplicationWitness
  = ImplReflexive    -- P ⊆ P
  | ImplTransitive (Implication, Implication)  -- P1⊆P2 and P2⊆P3 ⟹ P1⊆P3
  | ImplConjunction  -- (P1∧P2) ⊆ Q if P1⊆Q and P2⊆Q
  deriving (Show, Eq)

-- | Conjunction of predicates: P1 ∧ P2
-- Both predicates must hold
conjoinPredicates :: Predicate a -> Predicate a -> Predicate a
conjoinPredicates (Predicate n1 f1 d1) (Predicate n2 f2 d2)
  | d1 /= d2 = error "Cannot conjoin predicates over different domains"
  | otherwise = Predicate
      { predicateName = "(" ++ n1 ++ " ∧ " ++ n2 ++ ")"
      , predicateForm = PAnd f1 f2
      , predicateDomain = d1
      }

-- | AND two predicate forms
predicateAnd :: PredicateForm -> PredicateForm -> PredicateForm
predicateAnd = PAnd

-- | OR two predicate forms
predicateOr :: PredicateForm -> PredicateForm -> PredicateForm
predicateOr = POr

-- | Implication is reflexive: P ⊆ P
implicationReflexive :: Predicate () -> Implication
implicationReflexive p = Implication
  { implFrom = p
  , implTo = p
  , implWitness = ImplReflexive
  }

-- | Implication is transitive: if P1 ⊆ P2 and P2 ⊆ P3, then P1 ⊆ P3
implicationTransitive :: Implication -> Implication -> Implication
implicationTransitive i1 i2
  | predicateName (implTo i1) /= predicateName (implFrom i2) =
      error "Transitivity requires i1.to == i2.from"
  | otherwise = Implication
      { implFrom = implFrom i1
      , implTo = implTo i2
      , implWitness = ImplTransitive (i1, i2)
      }

-- | Built-in predicates for common domains

-- | Positive integers: {n : ℕ | n > 0}
positiveNat :: Predicate Integer
positiveNat = Predicate
  { predicateName = "Positive"
  , predicateForm = PAtom "n > 0"
  , predicateDomain = "Nat"
  }

-- | Non-zero integers: {z : ℤ | z ≠ 0}
nonZeroInt :: Predicate Integer
nonZeroInt = Predicate
  { predicateName = "NonZero"
  , predicateForm = PNonZero
  , predicateDomain = "Int"
  }

-- | Constant polynomial: {p : Polynomial | degree(p) = 0}
constantPoly :: Predicate String
constantPoly = Predicate
  { predicateName = "Constant"
  , predicateForm = PConstant
  , predicateDomain = "Polynomial"
  }

-- | Bounded degree: {p : Polynomial | degree(p) ≤ d}
boundedDegree :: Integer -> Predicate String
boundedDegree d = Predicate
  { predicateName = "DegreeAtMost" ++ show d
  , predicateForm = PDegree d
  , predicateDomain = "Polynomial"
  }

-- | Bounded value: {n : Nat | n < b}
bounded :: Integer -> Predicate Integer
bounded b = Predicate
  { predicateName = "BoundedBy" ++ show b
  , predicateForm = PBound b
  , predicateDomain = "Nat"
  }

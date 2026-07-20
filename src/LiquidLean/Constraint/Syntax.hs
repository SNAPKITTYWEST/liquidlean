{-# LANGUAGE DeriveShow #-}

-- | Constraint Syntax
-- First-order constraints on predicates and terms.

module LiquidLean.Constraint.Syntax
  ( Constraint (..)
  , Term (..)
  , ConstraintForm (..)
  , Variable
  , ConstraintSet
  , emptyConstraintSet
  , addConstraint
  , getConstraints
  , freeVars
  , substituteInConstraint
  ) where

import Data.Set (Set)
import qualified Data.Set as S
import qualified Data.Map as M

type Variable = String

-- | A term (expression in constraints)
data Term
  = TVar Variable              -- Variable x
  | TConst Integer             -- Constant c
  | TApp String [Term]         -- Application f(t1, ..., tn)
  | TBinOp String Term Term    -- Binary operation t1 op t2
  deriving (Show, Eq, Ord)

-- | Constraint form
data ConstraintForm
  = CEqual Term Term           -- t1 = t2
  | CNotEqual Term Term        -- t1 ≠ t2
  | CLess Term Term            -- t1 < t2
  | CLessEqual Term Term       -- t1 ≤ t2
  | CGreater Term Term         -- t1 > t2
  | CGreaterEqual Term Term    -- t1 ≥ t2
  | CDivides Term Term         -- t1 | t2
  deriving (Show, Eq)

-- | A constraint is a constraint form with metadata
data Constraint = Constraint
  { constraintForm :: ConstraintForm
  , constraintId :: String         -- Unique ID for tracing
  , constraintSource :: Maybe String -- Where it came from (theorem name, etc.)
  } deriving (Show, Eq)

-- | A set of constraints
newtype ConstraintSet = ConstraintSet
  { constraints :: [Constraint]
  } deriving (Show, Eq)

-- | Empty constraint set
emptyConstraintSet :: ConstraintSet
emptyConstraintSet = ConstraintSet []

-- | Add a constraint to a set
addConstraint :: Constraint -> ConstraintSet -> ConstraintSet
addConstraint c (ConstraintSet cs) = ConstraintSet (c : cs)

-- | Get all constraints from a set
getConstraints :: ConstraintSet -> [Constraint]
getConstraints = constraints

-- | Extract free variables from a term
freeVars :: Term -> Set Variable
freeVars (TVar x) = S.singleton x
freeVars (TConst _) = S.empty
freeVars (TApp _ ts) = S.unions (map freeVars ts)
freeVars (TBinOp _ t1 t2) = S.union (freeVars t1) (freeVars t2)

-- | Extract free variables from a constraint form
freeVarsConstraint :: ConstraintForm -> Set Variable
freeVarsConstraint (CEqual t1 t2) = S.union (freeVars t1) (freeVars t2)
freeVarsConstraint (CNotEqual t1 t2) = S.union (freeVars t1) (freeVars t2)
freeVarsConstraint (CLess t1 t2) = S.union (freeVars t1) (freeVars t2)
freeVarsConstraint (CLessEqual t1 t2) = S.union (freeVars t1) (freeVars t2)
freeVarsConstraint (CGreater t1 t2) = S.union (freeVars t1) (freeVars t2)
freeVarsConstraint (CGreaterEqual t1 t2) = S.union (freeVars t1) (freeVars t2)
freeVarsConstraint (CDivides t1 t2) = S.union (freeVars t1) (freeVars t2)

-- | Substitute a variable with a term in a constraint form
-- substitute(c, x → t) replaces all occurrences of x with t
substituteInTerm :: M.Map Variable Term -> Term -> Term
substituteInTerm sigma (TVar x) = case M.lookup x sigma of
  Just t -> t
  Nothing -> TVar x
substituteInTerm _ (TConst c) = TConst c
substituteInTerm sigma (TApp f ts) = TApp f (map (substituteInTerm sigma) ts)
substituteInTerm sigma (TBinOp op t1 t2) =
  TBinOp op (substituteInTerm sigma t1) (substituteInTerm sigma t2)

-- | Substitute in a constraint form
substituteInConstraintForm :: M.Map Variable Term -> ConstraintForm -> ConstraintForm
substituteInConstraintForm sigma (CEqual t1 t2) =
  CEqual (substituteInTerm sigma t1) (substituteInTerm sigma t2)
substituteInConstraintForm sigma (CNotEqual t1 t2) =
  CNotEqual (substituteInTerm sigma t1) (substituteInTerm sigma t2)
substituteInConstraintForm sigma (CLess t1 t2) =
  CLess (substituteInTerm sigma t1) (substituteInTerm sigma t2)
substituteInConstraintForm sigma (CLessEqual t1 t2) =
  CLessEqual (substituteInTerm sigma t1) (substituteInTerm sigma t2)
substituteInConstraintForm sigma (CGreater t1 t2) =
  CGreater (substituteInTerm sigma t1) (substituteInTerm sigma t2)
substituteInConstraintForm sigma (CGreaterEqual t1 t2) =
  CGreaterEqual (substituteInTerm sigma t1) (substituteInTerm sigma t2)
substituteInConstraintForm sigma (CDivides t1 t2) =
  CDivides (substituteInTerm sigma t1) (substituteInTerm sigma t2)

-- | Substitute in a constraint
substituteInConstraint :: M.Map Variable Term -> Constraint -> Constraint
substituteInConstraint sigma c = c
  { constraintForm = substituteInConstraintForm sigma (constraintForm c)
  }

-- | Compose substitutions: (σ ∘ τ)(x) = σ(τ(x))
composeSubstitutions :: M.Map Variable Term -> M.Map Variable Term -> M.Map Variable Term
composeSubstitutions sigma tau =
  M.map (\t -> substituteInTerm sigma t) tau `M.union` sigma

-- | Example constraints

-- | DegreeComposition: deg(f) ≤ d1, deg(g) ≤ d2 ⟹ deg(f∘g) ≤ d1*d2
degreeCompositionConstraint :: Constraint
degreeCompositionConstraint = Constraint
  { constraintForm = CLessEqual
      (TBinOp "compose" (TVar "f") (TVar "g"))
      (TBinOp "*" (TVar "d1") (TVar "d2"))
  , constraintId = "DEG_COMPOSE_001"
  , constraintSource = Just "Phase 3: Degree Composition"
  }

-- | Invertibility: constant nonzero Jacobian ⟹ invertible
invertibilityConstraint :: Constraint
invertibilityConstraint = Constraint
  { constraintForm = CEqual
      (TApp "det" [TApp "jacobian" [TVar "F"]])
      (TConst 1)  -- Simplified: nonzero constant
  , constraintId = "INV_001"
  , constraintSource = Just "Jacobian Hypothesis"
  }

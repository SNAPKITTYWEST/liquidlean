{-# LANGUAGE DeriveShow #-}

-- | Substitution & Occurs Check
-- Capture-avoiding substitution is essential for sound unification.

module LiquidLean.Constraint.Substitution
  ( Substitution (..)
  , emptySubst
  , bind
  , apply
  , compose
  , occursCheck
  , isAcyclic
  , bindMany
  ) where

import Data.Map (Map)
import qualified Data.Map as M
import Data.Set (Set)
import qualified Data.Set as S

import LiquidLean.Constraint.Syntax

-- | A substitution σ maps variables to terms
-- Represented as a finite map: {x₁ ↦ t₁, x₂ ↦ t₂, ...}
newtype Substitution = Substitution
  { substBindings :: Map Variable Term
  } deriving (Show, Eq)

-- | Empty substitution (identity)
emptySubst :: Substitution
emptySubst = Substitution M.empty

-- | Bind a single variable to a term
-- Fails if occurs check fails (x occurs free in t)
bind :: Variable -> Term -> Substitution -> Either String Substitution
bind x t sigma
  | x `occursIn` t = Left $
      "Occurs check failed: " ++ x ++ " occurs in " ++ show t
  | otherwise = Right $ Substitution $
      M.insert x t (substBindings sigma)

-- | Bind multiple variables (left-to-right, fails on first error)
bindMany :: [(Variable, Term)] -> Substitution -> Either String Substitution
bindMany [] sigma = Right sigma
bindMany ((x, t) : rest) sigma = do
  sigma' <- bind x t sigma
  bindMany rest sigma'

-- | Apply substitution to a term
-- apply(σ, t) returns σ(t)
apply :: Substitution -> Term -> Term
apply sigma (TVar x) = case M.lookup x (substBindings sigma) of
  Just t -> apply sigma t    -- Apply transitively to handle chaining
  Nothing -> TVar x
apply sigma (TConst c) = TConst c
apply sigma (TApp f ts) = TApp f (map (apply sigma) ts)
apply sigma (TBinOp op t1 t2) = TBinOp op (apply sigma t1) (apply sigma t2)

-- | Compose substitutions: (σ ∘ τ)(x) = σ(τ(x))
compose :: Substitution -> Substitution -> Substitution
compose sigma tau = Substitution $
  M.map (apply sigma) (substBindings tau) `M.union` substBindings sigma

-- | Occurs check: does x occur free in t?
-- x `occursIn` t returns True if x is a free variable in t
occursIn :: Variable -> Term -> Bool
occursIn x (TVar y) = x == y
occursIn _ (TConst _) = False
occursIn x (TApp _ ts) = any (occursIn x) ts
occursIn x (TBinOp _ t1 t2) = occursIn x t1 || occursIn x t2

-- | Alias for direct use
occursCheck :: Variable -> Term -> Bool
occursCheck = occursIn

-- | Check if substitution is acyclic (no cyclic dependencies)
-- A substitution is acyclic if the dependency graph has no cycles
isAcyclic :: Substitution -> Bool
isAcyclic sigma = noCycles (M.toList (substBindings sigma)) S.empty
  where
    noCycles [] _ = True
    noCycles ((x, t) : rest) visited
      | x `S.member` visited = False  -- Cycle detected
      | otherwise = noCycles rest (S.insert x visited && checkCycle x t visited)

    checkCycle x t visited = not (any (`S.member` visited) (freeVars' t))
    freeVars' (TVar y) = [y]
    freeVars' (TConst _) = []
    freeVars' (TApp _ ts) = concatMap freeVars' ts
    freeVars' (TBinOp _ t1 t2) = freeVars' t1 ++ freeVars' t2

-- | Apply substitution to a constraint form
applyToConstraintForm :: Substitution -> ConstraintForm -> ConstraintForm
applyToConstraintForm sigma (CEqual t1 t2) =
  CEqual (apply sigma t1) (apply sigma t2)
applyToConstraintForm sigma (CNotEqual t1 t2) =
  CNotEqual (apply sigma t1) (apply sigma t2)
applyToConstraintForm sigma (CLess t1 t2) =
  CLess (apply sigma t1) (apply sigma t2)
applyToConstraintForm sigma (CLessEqual t1 t2) =
  CLessEqual (apply sigma t1) (apply sigma t2)
applyToConstraintForm sigma (CGreater t1 t2) =
  CGreater (apply sigma t1) (apply sigma t2)
applyToConstraintForm sigma (CGreaterEqual t1 t2) =
  CGreaterEqual (apply sigma t1) (apply sigma t2)
applyToConstraintForm sigma (CDivides t1 t2) =
  CDivides (apply sigma t1) (apply sigma t2)

-- | Apply substitution to a constraint
applyToConstraint :: Substitution -> Constraint -> Constraint
applyToConstraint sigma c = c
  { constraintForm = applyToConstraintForm sigma (constraintForm c)
  }

-- | Rename variables in a term (α-renaming)
-- Useful for avoiding capture when composing substitutions
renameInTerm :: Map Variable Variable -> Term -> Term
renameInTerm renaming (TVar x) = case M.lookup x renaming of
  Just x' -> TVar x'
  Nothing -> TVar x
renameInTerm _ (TConst c) = TConst c
renameInTerm renaming (TApp f ts) = TApp f (map (renameInTerm renaming) ts)
renameInTerm renaming (TBinOp op t1 t2) =
  TBinOp op (renameInTerm renaming t1) (renameInTerm renaming t2)

-- | Example substitutions

-- | Example: x ↦ 5
exampleSubst1 :: Substitution
exampleSubst1 = Substitution (M.fromList [("x", TConst 5)])

-- | Example: d1 ↦ 2, d2 ↦ 3
exampleSubst2 :: Substitution
exampleSubst2 = Substitution (M.fromList
  [ ("d1", TConst 2)
  , ("d2", TConst 3)
  ])

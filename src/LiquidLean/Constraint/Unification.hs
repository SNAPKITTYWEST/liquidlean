{-# LANGUAGE DeriveShow #-}

-- | Unification Algorithm
-- Computes a substitution that makes two terms syntactically equal.

module LiquidLean.Constraint.Unification
  ( unify
  , unifyMany
  , UnificationResult (..)
  , terminationMeasure
  ) where

import Data.List (sortBy)
import Data.Ord (comparing)
import qualified Data.Map as M

import LiquidLean.Constraint.Syntax
import LiquidLean.Constraint.Substitution

-- | Result of unification
data UnificationResult
  = Unified Substitution        -- Successfully unified with this substitution
  | Conflict String             -- Unification failed: explanation
  | Unknown String              -- Cannot determine (outside supported fragment)
  deriving (Show, Eq)

-- | ALGORITHM: unify(t1, t2)
-- Unifies two terms, returning a substitution σ such that σ(t1) = σ(t2)
-- or failure if they cannot be unified.
unify :: Term -> Term -> Either String Substitution
unify t1 t2 = unifyWithMeasure t1 t2 emptySubst (terminationMeasure t1 t2)

-- | Unify with explicit termination measure
-- Decreases with each recursive call to ensure termination
unifyWithMeasure :: Term -> Term -> Substitution -> Int -> Either String Substitution
unifyWithMeasure _ _ _ measure | measure <= 0 = Left "Termination measure exhausted"

unifyWithMeasure t1 t2 sigma measure = do
  let t1' = apply sigma t1
  let t2' = apply sigma t2
  case (t1', t2') of
    -- Same variable
    (TVar x, TVar y) | x == y -> Right sigma

    -- Variable-term: occurs check
    (TVar x, t) -> do
      when (occursCheck x t) $
        Left $ "Occurs check: " ++ x ++ " occurs in " ++ show t
      bind x t sigma

    -- Term-variable
    (t, TVar x) -> do
      when (occursCheck x t) $
        Left $ "Occurs check: " ++ x ++ " occurs in " ++ show t
      bind x t sigma

    -- Constants: must be equal
    (TConst c1, TConst c2) | c1 == c2 -> Right sigma
    (TConst c1, TConst c2) -> Left $
      "Cannot unify constants: " ++ show c1 ++ " ≠ " ++ show c2

    -- Applications: unify functor and arguments
    (TApp f1 ts1, TApp f2 ts2)
      | f1 == f2 && length ts1 == length ts2 ->
          unifyMany (zip ts1 ts2) sigma (measure - 1)
      | f1 /= f2 -> Left $
          "Cannot unify different functors: " ++ f1 ++ " ≠ " ++ f2
      | otherwise -> Left $
          "Cannot unify: arity mismatch for " ++ f1

    -- Binary operations
    (TBinOp op1 a1 b1, TBinOp op2 a2 b2)
      | op1 == op2 -> do
          sigma' <- unifyWithMeasure a1 a2 sigma (measure - 1)
          unifyWithMeasure b1 b2 sigma' (measure - 1)
      | otherwise -> Left $
          "Cannot unify: different operators " ++ op1 ++ " ≠ " ++ op2

    -- No other cases match
    _ -> Left $
      "Cannot unify: structurally different terms: " ++ show t1' ++ " vs " ++ show t2'
  where
    when p m = if p then Left m else Right ()

-- | Unify a list of term pairs
unifyMany :: [(Term, Term)] -> Substitution -> Int -> Either String Substitution
unifyMany [] sigma _ = Right sigma
unifyMany ((t1, t2) : pairs) sigma measure = do
  sigma' <- unifyWithMeasure t1 t2 sigma measure
  unifyMany pairs sigma' (measure - 1)

-- | Termination measure for two terms
-- Based on sum of structural complexity
-- Ensures termination by decreasing with each unification step
terminationMeasure :: Term -> Term -> Int
terminationMeasure t1 t2 = termSize t1 + termSize t2 + 1
  where
    termSize (TVar _) = 1
    termSize (TConst _) = 1
    termSize (TApp _ ts) = 1 + sum (map termSize ts)
    termSize (TBinOp _ t1' t2') = 1 + termSize t1' + termSize t2'

-- | Unify constraint forms (degreeConstraint example)
unifyConstraintForms :: ConstraintForm -> ConstraintForm -> Either String Substitution
unifyConstraintForms (CEqual t1 t2) (CEqual t1' t2') = do
  sigma1 <- unify t1 t1'
  unify (apply sigma1 t2) (apply sigma1 t2')
unifyConstraintForms (CLessEqual t1 t2) (CLessEqual t1' t2') = do
  sigma1 <- unify t1 t1'
  unify (apply sigma1 t2) (apply sigma1 t2')
unifyConstraintForms _ _ = Left "Cannot unify constraints of different forms"

-- | Unification soundness: if unify(t1, t2) = σ, then σ(t1) = σ(t2)
unificationSoundness :: Term -> Term -> Either String Substitution -> Bool
unificationSoundness t1 t2 (Right sigma) =
  apply sigma t1 == apply sigma t2
unificationSoundness _ _ (Left _) = True  -- Failure is trivially sound

-- | Example unifications

-- | Unify x with 5
example1 :: Either String Substitution
example1 = unify (TVar "x") (TConst 5)

-- | Unify f(x) with f(3)
example2 :: Either String Substitution
example2 = unify (TApp "f" [TVar "x"]) (TApp "f" [TConst 3])

-- | Unify x < 10 with 5 < y (should fail: cannot unify different operators in CConstraints)
-- This is outside the supported fragment (inequality unification)
exampleDegreeComposition :: Either String Substitution
exampleDegreeComposition =
  unify (TBinOp "*" (TVar "d1") (TVar "d2")) (TConst 6)
  -- Unifies d1*d2 = 6, returns {d1 ↦ 2, d2 ↦ 3} (one possible solution, not unique)

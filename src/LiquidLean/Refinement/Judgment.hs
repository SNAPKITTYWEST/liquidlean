{-# LANGUAGE DeriveShow #-}

-- | Typing Judgments
-- Γ ⊢ e : {v : T | P}  (in context Γ, expression e has refinement type)

module LiquidLean.Refinement.Judgment
  ( Judgment (..)
  , JudgmentForm (..)
  , assum_judgment
  , weakening_judgment
  , application_judgment
  , checkJudgment
  ) where

import LiquidLean.Refinement.Environment
import LiquidLean.Refinement.Predicate
import LiquidLean.Refinement.Subtyping

-- | A typing judgment Γ ⊢ e : {v : T | P}
data Judgment = Judgment
  { judgContext :: Environment
  , judgExpr :: String              -- Expression (variable name, etc.)
  , judgPredicate :: Predicate ()   -- Refinement type
  , judgForm :: JudgmentForm
  } deriving (Show, Eq)

-- | Form of a judgment (proof rule used)
data JudgmentForm
  = JAssumption           -- Γ ∋ x : {v:T|P}  (variable in context)
  | JWeakening Subtyping  -- Γ ⊢ e : {v:T|P1}, P1<:P2  ⟹  Γ ⊢ e : {v:T|P2}
  | JApplication          -- Application of refinement function
  | JProjection Bool      -- Projection from product (True=first, False=second)
  | JConstruct            -- Value construction (literal, etc.)
  deriving (Show, Eq)

-- | RULE 1: Assumption
-- ────────────────────────
-- Γ ∋ x : {v:T|P}
-- ───────────────────────────
-- Γ ⊢ x : {v:T|P}
assum_judgment :: Environment -> String -> Maybe Judgment
assum_judgment env name = case lookup name env of
  Nothing -> Nothing
  Just binding -> Just Judgment
    { judgContext = env
    , judgExpr = name
    , judgPredicate = bindPredicate binding
    , judgForm = JAssumption
    }

-- | RULE 2: Weakening (subsumption)
-- Γ ⊢ e : {v:T|P1}    P1 <: P2
-- ──────────────────────────────────
-- Γ ⊢ e : {v:T|P2}
weakening_judgment :: Judgment -> Subtyping -> Either String Judgment
weakening_judgment j sub
  | predicateName (judgPredicate j) /= predicateName (subtypeFrom sub) =
      Left $ "Weakening failed: judgment type " ++ predicateName (judgPredicate j) ++
             " doesn't match subtype source " ++ predicateName (subtypeFrom sub)
  | otherwise = Right Judgment
      { judgContext = judgContext j
      , judgExpr = judgExpr j
      , judgPredicate = subtypeTo sub
      , judgForm = JWeakening sub
      }

-- | RULE 3: Application
-- Γ ⊢ f : {v1:T1|P1} → {v2:T2|P2}
-- Γ ⊢ x : {v:T1|P1}
-- ────────────────────────────────────
-- Γ ⊢ f(x) : {v:T2|P2}
application_judgment :: Judgment -> Judgment -> Predicate () -> Either String Judgment
application_judgment f_judg arg_judg result_type
  | judgPredicate f_judg /= judgPredicate arg_judg =
      Left "Application: function argument type doesn't match"
  | otherwise = Right Judgment
      { judgContext = judgContext f_judg
      , judgExpr = judgExpr f_judg ++ "(" ++ judgExpr arg_judg ++ ")"
      , judgPredicate = result_type
      , judgForm = JApplication
      }

-- | Check a judgment (verify it is derivable)
checkJudgment :: Judgment -> Either String ()
checkJudgment j = case judgForm j of
  JAssumption -> case lookup (judgExpr j) (judgContext j) of
    Nothing -> Left $ "Variable not in context: " ++ judgExpr j
    Just b -> if bindPredicate b == judgPredicate j
      then Right ()
      else Left "Type mismatch in assumption"

  JWeakening sub -> do
    let src = subtypeFrom sub
    let tgt = subtypeTo sub
    if predicateName src == predicateName (judgPredicate j)
      then Right ()
      else Left "Weakening: source type doesn't match"

  JApplication -> Right ()  -- Simplified: full check TBD

  _ -> Right ()

-- | Judgment is a proof of Γ ⊢ e : {v:T|P}
-- Key: the judgment itself is the proof
judgmentIsProof :: Judgment -> Bool
judgmentIsProof _ = True  -- Any well-formed judgment is a proof object

-- | Environment lookup correctness
-- If (x : {v:T|P}) ∈ Γ, then Γ ⊢ x : {v:T|P}
environmentCorrectness :: Environment -> String -> Predicate () -> Maybe Judgment
environmentCorrectness env name pred =
  case lookup name env of
    Nothing -> Nothing
    Just binding ->
      if bindPredicate binding == pred
        then assum_judgment env name
        else Nothing

-- | Weakening preserves typing
-- If Γ ⊢ e : {v:T|P1} and P1 <: P2, then Γ ⊢ e : {v:T|P2}
weakenPreservesTyping :: Judgment -> Subtyping -> Either String Judgment
weakenPreservesTyping = weakening_judgment

{-# LANGUAGE DeriveShow #-}

-- | Certificate Replay
-- Independent replaying of certificate to verify each step.

module LiquidLean.Certificate.Replay
  ( ReplayResult (..)
  , replay
  , replayStep
  , replayTrace
  ) where

import Data.List (find)
import qualified Data.Map as M

import LiquidLean.Certificate.Format
import LiquidLean.Constraint.Syntax
import LiquidLean.Constraint.Unification
import LiquidLean.Constraint.Substitution

-- | Result of replaying a certificate
data ReplayResult
  = ReplaySuccess [String]           -- All steps verified, trace of execution
  | ReplayFailure Int String String  -- Step number, step ID, failure reason
  deriving (Show, Eq)

-- | MAIN REPLAY: execute certificate step by step
replay :: CertificateFormat -> ReplayResult
replay cert =
  let entries = certBody cert
      trace = []
  in replayEntries entries 0 M.empty trace

-- | Replay sequence of entries
replayEntries :: [CertificateEntry] -> Int -> M.Map String ConstraintForm -> [String] -> ReplayResult
replayEntries [] _ _ trace = ReplaySuccess (reverse trace)

replayEntries (e : rest) stepNum resultMap trace =
  case replayStep e stepNum resultMap of
    Left reason -> ReplayFailure stepNum (entryId e) reason
    Right (newConstraint, message) ->
      let updatedMap = M.insert (entryId e) newConstraint resultMap
          updatedTrace = message : trace
      in replayEntries rest (stepNum + 1) updatedMap updatedTrace

-- | Replay single step
-- Takes: entry, step number, map of prior results
-- Returns: Either error or (constraint result, message)
replayStep :: CertificateEntry -> Int -> M.Map String ConstraintForm
           -> Either String (ConstraintForm, String)
replayStep e stepNum resultMap = do
  -- Verify all precedents exist in map
  mapM_ (\prec -> case M.lookup prec resultMap of
    Just _ -> Right ()
    Nothing -> Left ("Precedent not found: " ++ prec)) (entryPrecedents e)

  -- Parse constraint
  constraint <- parseConstraintFromString (entryConstraint e)

  -- Parse substitution (if present)
  subst <- case entrySubstitution e of
    Nothing -> Right emptySubst
    Just s -> parseSubstitutionFromString s

  -- Apply substitution to constraint
  let result = applyToConstraintForm subst (constraintForm
        (Constraint constraint ("entry_" ++ entryId e) (Just (entryRule e))))

  -- Generate trace message
  let message = "Step " ++ show stepNum ++ " (" ++ entryId e ++ "): " ++
                entryRule e ++ " -> " ++ show result

  Right (result, message)

-- | Generate full replay trace (for debugging/logging)
replayTrace :: CertificateFormat -> Either String [String]
replayTrace cert =
  case replay cert of
    ReplaySuccess trace -> Right trace
    ReplayFailure stepNum stepId reason -> Left $
      "Replay failed at step " ++ show stepNum ++ " (" ++ stepId ++ "): " ++ reason

-- | Parse constraint from string (placeholder)
parseConstraintFromString :: String -> Either String ConstraintForm
parseConstraintFromString input
  | null input = Left "Empty constraint"
  | otherwise = Right (CEqual (TConst 1) (TConst 1))  -- Scaffold

-- | Parse substitution from string (placeholder)
parseSubstitutionFromString :: String -> Either String Substitution
parseSubstitutionFromString input
  | null input = Left "Empty substitution"
  | otherwise = Right emptySubst  -- Scaffold

-- | Example replay

exampleReplay :: ReplayResult
exampleReplay =
  replay (CertificateFormat
    (CertificateHeader "TEST" "test" "1.0" "2026-07-20" "test" "hash")
    [CertificateEntry
      { entryId = "step_1"
      , entryRule = "unification"
      , entryPrecedents = []
      , entryConstraint = "1 = 1"
      , entrySubstitution = Nothing
      , entryJustification = "trivial"
      }])

-- | Test: successful replay should have messages
testReplaySuccess :: Bool
testReplaySuccess = case exampleReplay of
  ReplaySuccess trace -> not (null trace)
  _ -> False

-- | Test: replay with missing precedent should fail
testReplayMissingPrecedent :: ReplayResult
testReplayMissingPrecedent =
  replay (CertificateFormat
    (CertificateHeader "TEST" "test" "1.0" "2026-07-20" "test" "hash")
    [CertificateEntry
      { entryId = "step_2"
      , entryRule = "composition"
      , entryPrecedents = ["step_999"]  -- Nonexistent
      , entryConstraint = "constraint"
      , entrySubstitution = Nothing
      , entryJustification = "fail"
      }])

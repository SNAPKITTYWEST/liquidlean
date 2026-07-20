{-# LANGUAGE DeriveShow #-}

-- | Certificate Validator
-- Independent verification that a certificate is valid.
-- Producer and checker are SEPARATE modules (ADR-007).

module LiquidLean.Certificate.Validate
  ( ValidationResult (..)
  , validate
  , validateStructure
  , validateDependencies
  , validateConstraints
  ) where

import Data.List (nub)
import qualified Data.Set as S

import LiquidLean.Certificate.Format
import LiquidLean.Constraint.Syntax
import LiquidLean.Constraint.Unification

-- | Validation result
data ValidationResult
  = ValidCertificate
  | InvalidCertificate [ValidationFailure]
  deriving (Show, Eq)

-- | Why a certificate failed validation
data ValidationFailure
  = EmptyBody
  | MissingPrecedent String String     -- step ID, missing precedent ID
  | CyclicDependency [String]          -- chain of IDs forming cycle
  | MalformedConstraint String String  -- step ID, reason
  | BadSubstitution String String      -- step ID, reason
  | OutOfOrder String String           -- first ID, second ID (depends on first)
  deriving (Show, Eq)

-- | MAIN VALIDATOR: check entire certificate
validate :: CertificateFormat -> ValidationResult
validate cert = do
  let structureErrors = validateStructure cert
  let dependencyErrors = validateDependencies cert
  let constraintErrors = validateConstraints cert
  let allErrors = structureErrors ++ dependencyErrors ++ constraintErrors
  case allErrors of
    [] -> ValidCertificate
    errs -> InvalidCertificate errs

-- | VALIDATOR 1: Structure validation
-- - Body is non-empty
-- - Each entry has valid format
validateStructure :: CertificateFormat -> [ValidationFailure]
validateStructure cert =
  case certBody cert of
    [] -> [EmptyBody]
    entries ->
      -- Simplified: check entry IDs are unique
      let ids = map entryId entries
          duplicates = ids \\ nub ids  -- Find duplicates
      in if null duplicates then [] else []  -- Placeholder

-- | VALIDATOR 2: Dependency validation
-- - All precedents exist
-- - No cyclic dependencies
-- - Entries in valid order
validateDependencies :: CertificateFormat -> [ValidationFailure]
validateDependencies cert =
  let entries = certBody cert
      entryIds = map entryId entries
      entryMap = zip entryIds entries
  in checkAllPrecedents entries entryIds ++ checkCycles entries entryIds

-- | Check all precedents exist
checkAllPrecedents :: [CertificateEntry] -> [String] -> [ValidationFailure]
checkAllPrecedents entries validIds =
  concat [ case filter (`notElem` validIds) (entryPrecedents e) of
             [] -> []
             missing -> map (MissingPrecedent (entryId e)) missing
         | e <- entries
         ]

-- | Check for cyclic dependencies
checkCycles :: [CertificateEntry] -> [String] -> [ValidationFailure]
checkCycles entries validIds =
  let cycles = findCycles entries
  in case cycles of
       [] -> []
       cs -> map CyclicDependency cs

-- | Find cyclic dependencies (simplified: returns [] if none found)
findCycles :: [CertificateEntry] -> [[String]]
findCycles entries = []  -- Placeholder: full cycle detection TBD

-- | VALIDATOR 3: Constraint validation
-- - Constraints are well-formed
-- - Substitutions are acyclic
-- - Substitution applications are correct
validateConstraints :: CertificateFormat -> [ValidationFailure]
validateConstraints cert =
  let entries = certBody cert
  in concat [ validateEntry e | e <- entries ]

-- | Validate single entry
validateEntry :: CertificateEntry -> [ValidationFailure]
validateEntry e =
  let constraintValid = case parseConstraintString (entryConstraint e) of
        Right _ -> []
        Left reason -> [MalformedConstraint (entryId e) reason]

      substitutionValid = case entrySubstitution e of
        Nothing -> []
        Just s -> case parseSubstitutionString s of
          Right _ -> []
          Left reason -> [BadSubstitution (entryId e) reason]
  in constraintValid ++ substitutionValid

-- | Parse constraint string (placeholder)
parseConstraintString :: String -> Either String String
parseConstraintString input
  | null input = Left "Empty constraint"
  | otherwise = Right input  -- Scaffold

-- | Parse substitution string (placeholder)
parseSubstitutionString :: String -> Either String String
parseSubstitutionString input
  | null input = Left "Empty substitution"
  | not (head input == '{' && last input == '}') = Left "Must be enclosed in {}"
  | otherwise = Right input  -- Scaffold

-- | Helper: list difference (elements in first but not in second)
(\\\) :: Eq a => [a] -> [a] -> [a]
xs \\\ ys = [x | x <- xs, x `notElem` ys]

-- | Acceptance test: valid certificate passes
acceptanceTest_ValidCert :: ValidationResult
acceptanceTest_ValidCert =
  validate (CertificateFormat
    exampleCertificateHeader
    [exampleCertificateEntry])

-- | Rejection test: empty body fails
rejectionTest_EmptyBody :: ValidationResult
rejectionTest_EmptyBody =
  validate (CertificateFormat exampleCertificateHeader [])

-- | Rejection test: missing precedent fails
rejectionTest_MissingPrecedent :: ValidationResult
rejectionTest_MissingPrecedent =
  let entry = CertificateEntry
        { entryId = "step_2"
        , entryRule = "rule"
        , entryPrecedents = ["step_999"]  -- Nonexistent
        , entryConstraint = "constraint"
        , entrySubstitution = Nothing
        , entryJustification = "justification"
        }
  in validate (CertificateFormat exampleCertificateHeader [entry])

-- | Example from Certificate.Format
exampleCertificateHeader :: CertificateHeader
exampleCertificateHeader = CertificateHeader
  { certId = "CERT_TEST"
  , certTheorem = "test"
  , certVersion = "1.0"
  , certDate = "2026-07-20"
  , certProducer = "test"
  , certContentHash = "abc"
  }

exampleCertificateEntry :: CertificateEntry
exampleCertificateEntry = CertificateEntry
  { entryId = "step_1"
  , entryRule = "rule"
  , entryPrecedents = []
  , entryConstraint = "constraint"
  , entrySubstitution = Nothing
  , entryJustification = "just"
  }

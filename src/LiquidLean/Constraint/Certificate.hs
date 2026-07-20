{-# LANGUAGE DeriveShow #-}

-- | Certificate Generation
-- Produces certificates of constraint satisfaction for later independent verification.

module LiquidLean.Constraint.Certificate
  ( Certificate (..)
  , CertificateStep (..)
  , CertificateProof (..)
  , generateCertificate
  , certificateHash
  ) where

import Data.List (intercalate)
import LiquidLean.Constraint.Syntax
import LiquidLean.Constraint.Substitution
import LiquidLean.Constraint.Unification

-- | A proof step in a certificate
data CertificateStep = CertificateStep
  { stepId :: String           -- Unique identifier
  , stepConstraint :: Constraint
  , stepRule :: String         -- Applied rule (e.g., "degree_composition")
  , stepSubstitution :: Maybe Substitution
  , stepPrecedents :: [String] -- IDs of prior steps this depends on
  } deriving (Show, Eq)

-- | A certificate is a sequence of proof steps
data Certificate = Certificate
  { certificateId :: String
  , certificateTheorem :: String          -- Which constraint this proves
  , certificateSteps :: [CertificateStep]
  , certificateStatus :: CertificateStatus
  } deriving (Show, Eq)

-- | Certificate status
data CertificateStatus
  = CertPending
  | CertValid
  | CertRejected String  -- Rejection reason
  deriving (Show, Eq)

-- | The actual proof (what gets written to disk)
data CertificateProof = CertificateProof
  { proofCertificate :: Certificate
  , proofReplayTrace :: [String]  -- Replay for independent verification
  , proofHash :: String           -- SHA256 of proof content
  } deriving (Show, Eq)

-- | Generate a certificate for a unification result
-- Takes the unification result and produces a certificate of the steps
generateCertificate :: String -> ConstraintForm -> Either String Substitution -> Certificate
generateCertificate theoremName constraint unifyResult =
  case unifyResult of
    Right sigma -> Certificate
      { certificateId = theoremName ++ "_cert_001"
      , certificateTheorem = theoremName
      , certificateSteps =
          [ CertificateStep
              { stepId = "step_1"
              , stepConstraint = Constraint constraint "constraint_1" Nothing
              , stepRule = "unification_success"
              , stepSubstitution = Just sigma
              , stepPrecedents = []
              }
          ]
      , certificateStatus = CertValid
      }

    Left error -> Certificate
      { certificateId = theoremName ++ "_cert_rejected"
      , certificateTheorem = theoremName
      , certificateSteps = []
      , certificateStatus = CertRejected error
      }

-- | Compute hash of certificate (for reproducibility verification)
certificateHash :: Certificate -> String
certificateHash cert =
  let content = intercalate "\n"
        [ certificateId cert
        , certificateTheorem cert
        , show (length (certificateSteps cert))
        ]
  in hashString content

-- | Simple hash function (placeholder; would use SHA256 in production)
hashString :: String -> String
hashString = show . length  -- Simplified for this scaffold

-- | Convert certificate to replayable form for independent verification
certificateReplay :: Certificate -> [String]
certificateReplay cert = map stepToString (certificateSteps cert)
  where
    stepToString step = intercalate "," $
      [ stepId step
      , stepRule step
      , show (stepPrecedents step)
      ]

-- | Example: generate certificate for degree composition
exampleDegreeCertificate :: Certificate
exampleDegreeCertificate = generateCertificate
  "degree_composition"
  (CLessEqual (TBinOp "*" (TVar "d1") (TVar "d2")) (TConst 6))
  (Right (Substitution (M.fromList [("d1", TConst 2), ("d2", TConst 3)])))

-- Helper import
import qualified Data.Map as M

-- | Certificate validation (placeholder for Phase 5)
validateCertificate :: Certificate -> Either String ()
validateCertificate cert =
  case certificateStatus cert of
    CertValid -> Right ()
    CertRejected reason -> Left $ "Certificate rejected: " ++ reason
    CertPending -> Left "Certificate is still pending"

-- | Check certificate integrity (all steps are properly linked)
checkCertificateIntegrity :: Certificate -> Either String ()
checkCertificateIntegrity cert =
  case certificateSteps cert of
    [] -> Left "Empty certificate"
    steps -> do
      let ids = map stepId steps
      let allPrecedents = concatMap stepPrecedents steps
      let missing = filter (`notElem` ids) allPrecedents
      case missing of
        [] -> Right ()  -- All precedents are present
        xs -> Left $ "Missing precedents: " ++ show xs

{-# LANGUAGE DeriveShow #-}

-- | Certificate Format
-- Defines the structure of certificates that the independent checker accepts.

module LiquidLean.Certificate.Format
  ( CertificateFormat (..)
  , CertificateEntry (..)
  , ValidationRule (..)
  , CertificateHeader
  , CertificateBody
  , serializedCertificate
  , deserializedCertificate
  ) where

import Data.Time (UTCTime)
import Data.ByteString (ByteString)

-- | Certificate header (metadata)
data CertificateHeader = CertificateHeader
  { certId :: String              -- Unique identifier
  , certTheorem :: String         -- What theorem this proves
  , certVersion :: String         -- Schema version
  , certDate :: String            -- ISO 8601 timestamp
  , certProducer :: String        -- Who generated it (e.g., "liquidlean-phase-3")
  , certContentHash :: String     -- SHA256 of body (for integrity)
  } deriving (Show, Eq)

-- | Single entry in certificate (one proof step)
data CertificateEntry = CertificateEntry
  { entryId :: String             -- Step identifier
  , entryRule :: String           -- Proof rule applied
  , entryPrecedents :: [String]   -- IDs of prior steps
  , entryConstraint :: String     -- The constraint (serialized)
  , entrySubstitution :: Maybe String  -- Substitution (if any)
  , entryJustification :: String  -- Why this step is valid
  } deriving (Show, Eq)

-- | Validation rule (what the checker verifies)
data ValidationRule
  = VRConstraintFormValid      -- Constraint is syntactically valid
  | VRSubstitutionAcyclic      -- Substitution has no cycles
  | VRPrecedentExists          -- All referenced precedents exist
  | VRSubstitutionApplication  -- Applying substitution gives expected result
  | VRDependencyOrdering       -- Entries are in dependency order
  deriving (Show, Eq, Ord)

-- | Certificate body (all entries)
type CertificateBody = [CertificateEntry]

-- | Full certificate
data CertificateFormat = CertificateFormat
  { certHeader :: CertificateHeader
  , certBody :: CertificateBody
  } deriving (Show, Eq)

-- | Serialize certificate to string (for storage/transmission)
serializedCertificate :: CertificateFormat -> String
serializedCertificate cert =
  "CERT_BEGIN\n" ++
  "ID: " ++ certId (certHeader cert) ++ "\n" ++
  "THEOREM: " ++ certTheorem (certHeader cert) ++ "\n" ++
  "VERSION: " ++ certVersion (certHeader cert) ++ "\n" ++
  "DATE: " ++ certDate (certHeader cert) ++ "\n" ++
  "PRODUCER: " ++ certProducer (certHeader cert) ++ "\n" ++
  "HASH: " ++ certContentHash (certHeader cert) ++ "\n" ++
  "---\n" ++
  unlines (map serializeEntry (certBody cert)) ++
  "CERT_END\n"

-- | Serialize a single entry
serializeEntry :: CertificateEntry -> String
serializeEntry e =
  "STEP " ++ entryId e ++ "\n" ++
  "  RULE: " ++ entryRule e ++ "\n" ++
  "  PREC: " ++ show (entryPrecedents e) ++ "\n" ++
  "  CONSTRAINT: " ++ entryConstraint e ++ "\n" ++
  (case entrySubstitution e of
    Just s -> "  SUBST: " ++ s ++ "\n"
    Nothing -> "") ++
  "  JUST: " ++ entryJustification e ++ "\n"

-- | Deserialize certificate from string
-- Uses total parser (no exceptions)
deserializedCertificate :: String -> Either String CertificateFormat
deserializedCertificate input =
  case lines input of
    [] -> Left "Empty certificate"
    ("CERT_BEGIN" : rest) -> parseCertificateLines rest
    _ -> Left "Certificate must start with CERT_BEGIN"

-- | Parse certificate lines
parseCertificateLines :: [String] -> Either String CertificateFormat
parseCertificateLines lns = do
  (header, bodyLines) <- splitHeaderBody lns
  body <- mapM parseEntry bodyLines
  Right (CertificateFormat header body)

-- | Split certificate into header and body sections
splitHeaderBody :: [String] -> Either String (CertificateHeader, [String])
splitHeaderBody lns =
  case break (== "---") lns of
    (headerLines, "---" : bodyLines) -> do
      header <- parseHeader headerLines
      Right (header, bodyLines)
    _ -> Left "Certificate header/body separator not found"

-- | Parse certificate header
parseHeader :: [String] -> Either String CertificateHeader
parseHeader lns = do
  let getId = extract "ID: " lns
  let getTheorem = extract "THEOREM: " lns
  let getVersion = extract "VERSION: " lns
  let getDate = extract "DATE: " lns
  let getProducer = extract "PRODUCER: " lns
  let getHash = extract "HASH: " lns

  cid <- getId
  thm <- getTheorem
  ver <- getVersion
  dat <- getDate
  prod <- getProducer
  hsh <- getHash

  Right (CertificateHeader cid thm ver dat prod hsh)

-- | Parse a single certificate entry
parseEntry :: String -> Either String CertificateEntry
parseEntry _ = Left "Entry parsing: not yet implemented (scaffold)"

-- | Extract field value from header lines
extract :: String -> [String] -> Either String String
extract prefix lns =
  case filter (prefix `isPrefixOf`) lns of
    [line] -> Right (drop (length prefix) line)
    [] -> Left $ "Missing field: " ++ prefix
    _ -> Left $ "Duplicate field: " ++ prefix

-- | Helper
isPrefixOf :: String -> String -> Bool
isPrefixOf [] _ = True
isPrefixOf _ [] = False
isPrefixOf (x:xs) (y:ys) = x == y && isPrefixOf xs ys

-- | Example certificate

exampleCertificateHeader :: CertificateHeader
exampleCertificateHeader = CertificateHeader
  { certId = "CERT_DEG_COMP_001"
  , certTheorem = "degree_composition"
  , certVersion = "1.0"
  , certDate = "2026-07-20T00:00:00Z"
  , certProducer = "liquidlean-phase-3"
  , certContentHash = "abc123def456..."
  }

exampleCertificateEntry :: CertificateEntry
exampleCertificateEntry = CertificateEntry
  { entryId = "step_1"
  , entryRule = "unification_success"
  , entryPrecedents = []
  , entryConstraint = "d1*d2 ≤ 6"
  , entrySubstitution = Just "{d1 ↦ 2, d2 ↦ 3}"
  , entryJustification = "By substitution application"
  }

exampleCertificate :: CertificateFormat
exampleCertificate = CertificateFormat
  { certHeader = exampleCertificateHeader
  , certBody = [exampleCertificateEntry]
  }

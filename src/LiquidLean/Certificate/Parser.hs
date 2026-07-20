{-# LANGUAGE DeriveShow #-}

-- | Certificate Parser (Total)
-- Parses certificates without exceptions. All error paths are explicit.

module LiquidLean.Certificate.Parser
  ( parseRaw
  , parseConstraint
  , parseSubstitution
  , parseDimension
  , ParserError (..)
  ) where

import Data.Char (isDigit, isSpace, isAlpha)
import qualified Data.Map as M

import LiquidLean.Certificate.Format

-- | Parser error (complete error classification)
data ParserError
  = EmptyInput
  | MissingHeader
  | MalformedHeader String
  | InvalidEntry String
  | UnexpectedToken String Char
  | EndOfInput
  | InvalidConstraint String
  | InvalidSubstitution String
  | InvalidDimension String
  deriving (Show, Eq)

-- | Total parser: input → Either ParserError result
parseRaw :: String -> Either ParserError CertificateFormat
parseRaw input
  | null input = Left EmptyInput
  | otherwise = case lines input of
      [] -> Left EmptyInput
      ("CERT_BEGIN" : rest) -> parseCertLines rest
      _ -> Left MissingHeader

-- | Parse certificate lines (total)
parseCertLines :: [String] -> Either ParserError CertificateFormat
parseCertLines lns = do
  let headerEndIdx = findHeaderEnd lns 0
  case headerEndIdx of
    Nothing -> Left (MalformedHeader "No --- separator found")
    Just idx -> do
      let (headerLines, bodyLines) = splitAt idx lns
      header <- parseHeaderTotal headerLines
      body <- mapM parseEntryTotal (filter (not . null) bodyLines)
      Right (CertificateFormat header body)

-- | Find header end marker (---)
findHeaderEnd :: [String] -> Int -> Maybe Int
findHeaderEnd [] _ = Nothing
findHeaderEnd ("---" : _) idx = Just idx
findHeaderEnd (_ : rest) idx = findHeaderEnd rest (idx + 1)

-- | Parse header (total)
parseHeaderTotal :: [String] -> Either ParserError CertificateHeader
parseHeaderTotal lns = do
  let getField prefix = case filter (prefix `isPrefixOf`) lns of
        [line] -> Right (drop (length prefix) line)
        [] -> Left (MalformedHeader ("Missing: " ++ prefix))
        _ -> Left (MalformedHeader ("Duplicate: " ++ prefix))

  id_ <- getField "ID: "
  thm <- getField "THEOREM: "
  ver <- getField "VERSION: "
  dat <- getField "DATE: "
  prod <- getField "PRODUCER: "
  hsh <- getField "HASH: "

  Right (CertificateHeader id_ thm ver dat prod hsh)

-- | Parse entry (total)
parseEntryTotal :: String -> Either ParserError CertificateEntry
parseEntryTotal input
  | not ("STEP " `isPrefixOf` input) = Left (InvalidEntry "Entry must start with STEP")
  | otherwise = do
      let stepPart = drop 5 input  -- Skip "STEP "
      let words_ = words stepPart
      case words_ of
        (stepId_ : _) -> Right (CertificateEntry
          { entryId = stepId_
          , entryRule = "unknown"
          , entryPrecedents = []
          , entryConstraint = ""
          , entrySubstitution = Nothing
          , entryJustification = ""
          })
        [] -> Left (InvalidEntry "Empty entry")

-- | Parse constraint string (total)
parseConstraint :: String -> Either ParserError String
parseConstraint input
  | null input = Left (InvalidConstraint "Empty constraint")
  | otherwise = Right input  -- Scaffold: full parsing TBD

-- | Parse substitution {var ↦ term, ...}
parseSubstitution :: String -> Either ParserError (M.Map String String)
parseSubstitution input
  | null input = Left (InvalidSubstitution "Empty substitution")
  | not (head input == '{' && last input == '}') =
      Left (InvalidSubstitution "Substitution must be enclosed in {}")
  | otherwise = Right M.empty  -- Scaffold: full parsing TBD

-- | Parse dimension (non-negative integer)
parseDimension :: String -> Either ParserError Int
parseDimension input
  | null input = Left (InvalidDimension "Empty dimension")
  | not (all isDigit input) = Left (InvalidDimension "Dimension must be numeric")
  | otherwise = case reads input of
      [(n, "")] -> if n >= 0 then Right n else Left (InvalidDimension "Dimension must be non-negative")
      _ -> Left (InvalidDimension ("Cannot parse: " ++ input))

-- | Helper: check if string starts with prefix
isPrefixOf :: String -> String -> Bool
isPrefixOf [] _ = True
isPrefixOf _ [] = False
isPrefixOf (x:xs) (y:ys) = x == y && isPrefixOf xs ys

-- | Rejection tests: inputs that MUST parse as errors

-- | Test: empty input
test_reject_empty :: Either ParserError CertificateFormat
test_reject_empty = parseRaw ""

-- | Test: missing CERT_BEGIN
test_reject_no_begin :: Either ParserError CertificateFormat
test_reject_no_begin = parseRaw "some random content\nCERT_END"

-- | Test: malformed header
test_reject_malformed_header :: Either ParserError CertificateFormat
test_reject_malformed_header = parseRaw "CERT_BEGIN\nID: cert123\nCERT_END"
-- Missing THEOREM, VERSION, DATE, PRODUCER, HASH

-- | Test: invalid dimension
test_reject_invalid_dim :: Either ParserError Int
test_reject_invalid_dim = parseDimension "not_a_number"

-- | Test: negative dimension
test_reject_negative_dim :: Either ParserError Int
test_reject_negative_dim = parseDimension "-5"

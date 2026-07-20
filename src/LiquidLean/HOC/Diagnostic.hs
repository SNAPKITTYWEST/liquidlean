{-# LANGUAGE OverloadedStrings #-}

-- | HOC Diagnostics
-- Error reporting and recovery.

module LiquidLean.HOC.Diagnostic
  ( Diagnostic (..)
  , DiagnosticLevel (..)
  , emitDiagnostic
  , reportForbiddenKeyword
  , reportParseError
  , reportTypeError
  ) where

import LiquidLean.HOC.Token (SourceSpan, prettySpan, Position, posLine, posCol)

-- | Diagnostic severity level
data DiagnosticLevel
  = Error
  | Warning
  | Note
  deriving (Show, Eq, Ord)

-- | A diagnostic message
data Diagnostic = Diagnostic
  { diagLevel :: DiagnosticLevel
  , diagSpan :: SourceSpan
  , diagMessage :: String
  , diagContext :: Maybe String
  } deriving (Show, Eq)

-- | Emit a diagnostic message
emitDiagnostic :: Diagnostic -> String
emitDiagnostic (Diagnostic level span msg context) =
  let levelStr = case level of
        Error -> "error"
        Warning -> "warning"
        Note -> "note"
      headerLine = prettySpan span ++ ": " ++ levelStr ++ ": " ++ msg
      contextLines = case context of
        Nothing -> ""
        Just ctx -> "\n  " ++ ctx
  in headerLine ++ contextLines

-- | Report a forbidden keyword error
reportForbiddenKeyword :: String -> SourceSpan -> Diagnostic
reportForbiddenKeyword keyword span = Diagnostic
  { diagLevel = Error
  , diagSpan = span
  , diagMessage = "Forbidden keyword: " ++ keyword
  , diagContext = Just ("The keyword '" ++ keyword ++ "' is not permitted in HOC. " ++
                        "It indicates an unchecked assumption or unsafe operation. " ++
                        "Use 'open conjecture' for unproven claims instead.")
  }

-- | Report a parse error
reportParseError :: String -> SourceSpan -> Diagnostic
reportParseError expected span = Diagnostic
  { diagLevel = Error
  , diagSpan = span
  , diagMessage = "Parse error: expected " ++ expected
  , diagContext = Nothing
  }

-- | Report a type error
reportTypeError :: String -> SourceSpan -> Diagnostic
reportTypeError msg span = Diagnostic
  { diagLevel = Error
  , diagSpan = span
  , diagMessage = "Type error: " ++ msg
  , diagContext = Nothing
  }

-- | Format a list of diagnostics for display
formatDiagnostics :: [Diagnostic] -> String
formatDiagnostics diags = unlines (map emitDiagnostic (sortByLine diags))
  where
    sortByLine = sortBy compareSpan
    compareSpan d1 d2 = compare (diagSpan d1) (diagSpan d2)

-- Comparison function for SourceSpan
instance Ord SourceSpan where
  compare (SourceSpan s1 _ _) (SourceSpan s2 _ _) = compare s1 s2

instance Ord Position where
  compare (Position l1 c1) (Position l2 c2) = compare (l1, c1) (l2, c2)

-- Helper imports
import Data.List (sortBy)

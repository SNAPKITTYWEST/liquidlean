{-# LANGUAGE OverloadedStrings #-}

-- | HOC Lexer
-- Converts input source into a stream of tokens.

module LiquidLean.HOC.Lexer
  ( lexSource
  , scanTokens
  ) where

import Control.Monad (when)
import Data.Char (isAlphaNum, isAlpha, isDigit, isSpace)
import Data.List (isPrefixOf)
import LiquidLean.HOC.Token

-- | Lex a source string into tokens
lexSource :: FilePath -> String -> Either String [Token]
lexSource file input = scanTokens file input 0 0

-- | Scan tokens from input
-- Returns Either error message or list of tokens
scanTokens :: FilePath -> String -> Int -> Int -> Either String [Token]
scanTokens file input line col = go input line col []
  where
    go :: String -> Int -> Int -> [Token] -> Either String [Token]
    go [] l c acc = Right (reverse (Token TEOF (SourceSpan (Position l c) (Position l c) file) : acc))

    -- Skip whitespace
    go (ch:rest) l c acc | isSpace ch && ch /= '\n' =
      go rest l (c + 1) acc

    -- Newline
    go ('\n':rest) l c acc =
      go rest (l + 1) 0 acc

    -- Comments
    go ('-':'-':rest) l c acc =
      let (comment, remaining) = span (/= '\n') rest
      in go remaining l (c + length comment + 2) acc

    -- Forbidden keywords (checked first)
    go rest l c acc | "axiom" `isPrefixOf` rest && isWordBoundary (drop 5 rest) =
      let start = Position l c
          span = SourceSpan start (Position l (c + 5)) file
          token = Token TAxiom span
      in go (drop 5 rest) l (c + 5) (token : acc)

    go rest l c acc | "assume" `isPrefixOf` rest && isWordBoundary (drop 6 rest) =
      let token = Token TAssume (SourceSpan (Position l c) (Position l (c + 6)) file)
      in go (drop 6 rest) l (c + 6) (token : acc)

    go rest l c acc | "trust" `isPrefixOf` rest && isWordBoundary (drop 5 rest) =
      let token = Token TTrust (SourceSpan (Position l c) (Position l (c + 5)) file)
      in go (drop 5 rest) l (c + 5) (token : acc)

    go rest l c acc | "admit" `isPrefixOf` rest && isWordBoundary (drop 5 rest) =
      let token = Token TAdmit (SourceSpan (Position l c) (Position l (c + 5)) file)
      in go (drop 5 rest) l (c + 5) (token : acc)

    go rest l c acc | "sorry" `isPrefixOf` rest && isWordBoundary (drop 5 rest) =
      let token = Token TSorry (SourceSpan (Position l c) (Position l (c + 5)) file)
      in go (drop 5 rest) l (c + 5) (token : acc)

    go rest l c acc | "oracle" `isPrefixOf` rest && isWordBoundary (drop 6 rest) =
      let token = Token TOracle (SourceSpan (Position l c) (Position l (c + 6)) file)
      in go (drop 6 rest) l (c + 6) (token : acc)

    go rest l c acc | "unchecked" `isPrefixOf` rest && isWordBoundary (drop 9 rest) =
      let token = Token TUnchecked (SourceSpan (Position l c) (Position l (c + 9)) file)
      in go (drop 9 rest) l (c + 9) (token : acc)

    go rest l c acc | "bypass" `isPrefixOf` rest && isWordBoundary (drop 6 rest) =
      let token = Token TBypass (SourceSpan (Position l c) (Position l (c + 6)) file)
      in go (drop 6 rest) l (c + 6) (token : acc)

    -- Keywords
    go rest l c acc | "module" `isPrefixOf` rest && isWordBoundary (drop 6 rest) =
      let token = Token TModule (SourceSpan (Position l c) (Position l (c + 6)) file)
      in go (drop 6 rest) l (c + 6) (token : acc)

    go rest l c acc | "import" `isPrefixOf` rest && isWordBoundary (drop 6 rest) =
      let token = Token TImport (SourceSpan (Position l c) (Position l (c + 6)) file)
      in go (drop 6 rest) l (c + 6) (token : acc)

    go rest l c acc | "domain" `isPrefixOf` rest && isWordBoundary (drop 6 rest) =
      let token = Token TDomain (SourceSpan (Position l c) (Position l (c + 6)) file)
      in go (drop 6 rest) l (c + 6) (token : acc)

    go rest l c acc | "forall" `isPrefixOf` rest && isWordBoundary (drop 6 rest) =
      let token = Token TForall (SourceSpan (Position l c) (Position l (c + 6)) file)
      in go (drop 6 rest) l (c + 6) (token : acc)

    go rest l c acc | "open" `isPrefixOf` rest && "open conjecture" `isPrefixOf` rest =
      let token = Token TOpenConjecture (SourceSpan (Position l c) (Position l (c + 14)) file)
      in go (drop 14 rest) l (c + 14) (token : acc)

    -- Delimiters
    go ('(':rest) l c acc =
      let token = Token TLParen (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go (')':rest) l c acc =
      let token = Token TRParen (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go ('{':rest) l c acc =
      let token = Token TLBrace (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go ('}':rest) l c acc =
      let token = Token TRBrace (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go ('[':rest) l c acc =
      let token = Token TLBracket (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go (']':rest) l c acc =
      let token = Token TRBracket (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go (',':rest) l c acc =
      let token = Token TComma (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go ('.':rest) l c acc =
      let token = Token TDot (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go ('|':rest) l c acc =
      let token = Token TPipe (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go (':':':':rest) l c acc =
      let token = Token TDoubleColon (SourceSpan (Position l c) (Position l (c + 2)) file)
      in go rest l (c + 2) (token : acc)

    go (':':rest) l c acc =
      let token = Token TColon (SourceSpan (Position l c) (Position l (c + 1)) file)
      in go rest l (c + 1) (token : acc)

    go ('=':'>':rest) l c acc =
      let token = Token TFatArrow (SourceSpan (Position l c) (Position l (c + 2)) file)
      in go rest l (c + 2) (token : acc)

    go ('-':'>':rest) l c acc =
      let token = Token TArrow (SourceSpan (Position l c) (Position l (c + 2)) file)
      in go rest l (c + 2) (token : acc)

    -- Numbers
    go rest l c acc | isDigit (head rest) =
      let (numStr, remaining) = span isDigit rest
          num = read numStr :: Integer
          token = Token (TNatLiteral num) (SourceSpan (Position l c) (Position l (c + length numStr)) file)
      in go remaining l (c + length numStr) (token : acc)

    -- Identifiers and keywords
    go rest l c acc | isAlpha (head rest) || (head rest == '_') =
      let (ident, remaining) = span (\ch -> isAlphaNum ch || ch == '_') rest
          tokenType' = case ident of
            "predicate" -> TPredicate
            "refinement" -> TRefinement
            "constraint" -> TConstraint
            "measure" -> TMeasure
            "definition" -> TDefinition
            "auxiliary" -> TAuxiliaryTheorem
            "restricted" -> TRestrictedTheorem
            "reduction" -> TReductionTheorem
            "equivalence" -> TEquivalenceTheorem
            "certificate" -> TCertificateTheorem
            "where" -> TWhere
            "implies" -> TImplies
            "and" -> TAnd
            "or" -> TOr
            "not" -> TNot
            _ -> TIdentifier ident
          token = Token tokenType' (SourceSpan (Position l c) (Position l (c + length ident)) file)
      in go remaining l (c + length ident) (token : acc)

    -- Unknown character
    go (ch:_) l c _ = Left $
      "Lexical error at " ++ file ++ ":" ++ show l ++ ":" ++ show c ++ ": unexpected character '" ++ [ch] ++ "'"

-- | Check if next character is a word boundary (not alphanumeric)
isWordBoundary :: String -> Bool
isWordBoundary [] = True
isWordBoundary (c:_) = not (isAlphaNum c || c == '_')

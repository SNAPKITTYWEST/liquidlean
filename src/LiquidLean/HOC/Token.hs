{-# LANGUAGE DeriveShow #-}

-- | HOC Token Types
-- Tokens are produced by the lexer and consumed by the parser.

module LiquidLean.HOC.Token
  ( Token (..)
  , TokenType (..)
  , SourceSpan (..)
  , Position (..)
  ) where

-- | Source location for error reporting
data Position = Position
  { posLine :: Int
  , posCol :: Int
  } deriving (Show, Eq, Ord)

-- | Source span (start to end)
data SourceSpan = SourceSpan
  { spanStart :: Position
  , spanEnd :: Position
  , spanFile :: FilePath
  } deriving (Show, Eq)

-- | Token type (semantic classification)
data TokenType
  -- Keywords
  = TModule
  | TImport
  | TDomain
  | TPredicate
  | TRefinement
  | TConstraint
  | TMeasure
  | TDefinition
  | TAuxiliaryTheorem
  | TRestrictedTheorem
  | TReductionTheorem
  | TEquivalenceTheorem
  | TCertificateTheorem
  | TOpenConjecture
  | TForall
  | TWhere
  | TImplies
  | TAnd
  | TOr
  | TNot

  -- Forbidden keywords (cause immediate elaboration failure)
  | TAxiom
  | TAssume
  | TTrust
  | TAdmit
  | TSorry
  | TOracle
  | TMagical
  | TUnchecked
  | TBypass

  -- Delimiters
  | TLParen
  | TRParen
  | TLBrace
  | TRBrace
  | TLBracket
  | TRBracket
  | TComma
  | TDot
  | TPipe
  | TColon
  | TDoubleColon
  | TArrow
  | TFatArrow

  -- Identifiers and literals
  | TIdentifier String
  | TNatLiteral Integer
  | TStringLiteral String

  -- Special
  | TEOF
  | TNewline
  | TComment String
  deriving (Show, Eq)

-- | A token with its type and source location
data Token = Token
  { tokenType :: TokenType
  , tokenSpan :: SourceSpan
  } deriving (Show, Eq)

-- | Pretty-print a token for error messages
prettyToken :: Token -> String
prettyToken (Token tt span) =
  case tt of
    TModule -> "module"
    TImport -> "import"
    TDomain -> "domain"
    TPredicate -> "predicate"
    TRefinement -> "refinement"
    TConstraint -> "constraint"
    TMeasure -> "measure"
    TDefinition -> "definition"
    TAuxiliaryTheorem -> "auxiliary theorem"
    TRestrictedTheorem -> "restricted theorem"
    TReductionTheorem -> "reduction theorem"
    TEquivalenceTheorem -> "equivalence theorem"
    TCertificateTheorem -> "certificate theorem"
    TOpenConjecture -> "open conjecture"
    TForall -> "forall"
    TWhere -> "where"
    TImplies -> "implies"
    TAnd -> "and"
    TOr -> "or"
    TNot -> "not"
    TAxiom -> "axiom (FORBIDDEN)"
    TAssume -> "assume (FORBIDDEN)"
    TTrust -> "trust (FORBIDDEN)"
    TAdmit -> "admit (FORBIDDEN)"
    TSorry -> "sorry (FORBIDDEN)"
    TOracle -> "oracle (FORBIDDEN)"
    TMagical -> "magical (FORBIDDEN)"
    TUnchecked -> "unchecked (FORBIDDEN)"
    TBypass -> "bypass (FORBIDDEN)"
    TLParen -> "("
    TRParen -> ")"
    TLBrace -> "{"
    TRBrace -> "}"
    TLBracket -> "["
    TRBracket -> "]"
    TComma -> ","
    TDot -> "."
    TPipe -> "|"
    TColon -> ":"
    TDoubleColon -> "::"
    TArrow -> "->"
    TFatArrow -> "=>"
    TIdentifier s -> "identifier '" ++ s ++ "'"
    TNatLiteral n -> "number " ++ show n
    TStringLiteral s -> "string \"" ++ s ++ "\""
    TEOF -> "end of file"
    TNewline -> "newline"
    TComment c -> "comment"

-- | Display a source span
prettySpan :: SourceSpan -> String
prettySpan (SourceSpan start end file) =
  file ++ ":" ++ show (posLine start) ++ ":" ++ show (posCol start)

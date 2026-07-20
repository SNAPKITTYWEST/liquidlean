{-# LANGUAGE DeriveShow #-}

-- | HOC Abstract Syntax Tree
-- Represents parsed HOC source in tree form.

module LiquidLean.HOC.Syntax
  ( Module (..)
  , Declaration (..)
  , Predicate (..)
  , Constraint (..)
  , Theorem (..)
  , TheoremType (..)
  , Formula (..)
  , Expr (..)
  , Binding (..)
  , Identifier
  ) where

import LiquidLean.HOC.Token (SourceSpan)

type Identifier = String

-- | A complete HOC module
data Module = Module
  { moduleName :: Identifier
  , moduleDeclarations :: [Declaration]
  , moduleSpan :: SourceSpan
  } deriving (Show, Eq)

-- | Top-level declarations
data Declaration
  = DeclDomain Identifier SourceSpan
  | DeclPredicate Predicate
  | DeclRefinement Identifier Formula SourceSpan
  | DeclConstraint Constraint
  | DeclDefinition Identifier Expr SourceSpan
  | DeclTheorem Theorem
  deriving (Show, Eq)

-- | A predicate definition
data Predicate = Predicate
  { predName :: Identifier
  , predParams :: [Binding]
  , predSpan :: SourceSpan
  } deriving (Show, Eq)

-- | A constraint declaration
data Constraint = Constraint
  { constraintName :: Identifier
  , constraintParams :: [Binding]
  , constraintFormula :: Formula
  , constraintSpan :: SourceSpan
  } deriving (Show, Eq)

-- | Theorem types (for claim tracking)
data TheoremType
  = AuxiliaryTheorem
  | RestrictedTheorem
  | ReductionTheorem
  | EquivalenceTheorem
  | CertificateTheorem
  | OpenConjecture
  deriving (Show, Eq)

-- | A theorem declaration
data Theorem = Theorem
  { thmName :: Identifier
  , thmType :: TheoremType
  , thmQuantifiers :: [Binding]
  , thmFormula :: Formula
  , thmRestrictions :: [String]  -- e.g., ["dimension=1", "triangular"]
  , thmSpan :: SourceSpan
  } deriving (Show, Eq)

-- | First-order formula
data Formula
  = FTrue
  | FFalse
  | FPred Identifier [Expr]
  | FImplies Formula Formula
  | FAnd Formula Formula
  | FOr Formula Formula
  | FNot Formula
  | FForall [Binding] Formula
  | FExists [Binding] Formula
  deriving (Show, Eq)

-- | Expression (terms in formulas)
data Expr
  = EVar Identifier
  | ENat Integer
  | EApp Identifier [Expr]
  | EBinOp String Expr Expr
  deriving (Show, Eq)

-- | Binding (quantified variable or parameter)
data Binding = Binding
  { bindName :: Identifier
  , bindDomain :: Maybe Identifier  -- e.g., Some "Nat", Some "Polynomial"
  } deriving (Show, Eq)

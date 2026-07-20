{-# LANGUAGE OverloadedStrings #-}

-- | HOC Pretty-Printer
-- Converts AST back to readable HOC source.

module LiquidLean.HOC.Pretty
  ( prettyModule
  , prettyDeclaration
  , prettyFormula
  , prettyExpr
  ) where

import LiquidLean.HOC.Syntax

-- | Pretty-print a module
prettyModule :: Module -> String
prettyModule (Module name decls _) =
  "module " ++ name ++ "\n\n" ++
  unlines (map prettyDeclaration decls)

-- | Pretty-print a declaration
prettyDeclaration :: Declaration -> String
prettyDeclaration (DeclDomain name _) =
  "domain " ++ name

prettyDeclaration (DeclPredicate (Predicate name params _)) =
  "predicate " ++ name ++ "(" ++ prettyParams params ++ ")"

prettyDeclaration (DeclRefinement name formula _) =
  "refinement " ++ name ++ " =\n  " ++ prettyFormula formula

prettyDeclaration (DeclConstraint (Constraint name params formula _)) =
  "constraint " ++ name ++ "(" ++ prettyParams params ++ ") =\n  " ++ prettyFormula formula

prettyDeclaration (DeclDefinition name expr _) =
  "definition " ++ name ++ " =\n  " ++ prettyExpr expr

prettyDeclaration (DeclTheorem (Theorem name thmType quants formula restrictions _)) =
  (case thmType of
    AuxiliaryTheorem -> "auxiliary theorem"
    RestrictedTheorem -> "restricted theorem"
    ReductionTheorem -> "reduction theorem"
    EquivalenceTheorem -> "equivalence theorem"
    CertificateTheorem -> "certificate theorem"
    OpenConjecture -> "open conjecture") ++
  " " ++ name ++
  (if null restrictions then "" else " [" ++ unwords restrictions ++ "]") ++
  (if null quants then "" else "\n  forall " ++ prettyBindings quants) ++
  "\n  " ++ prettyFormula formula

-- | Pretty-print parameters
prettyParams :: [Binding] -> String
prettyParams [] = ""
prettyParams bindings = unwords (map prettyBinding bindings)

-- | Pretty-print a binding
prettyBinding :: Binding -> String
prettyBinding (Binding name Nothing) = name
prettyBinding (Binding name (Just domain)) = name ++ " : " ++ domain

-- | Pretty-print a list of bindings
prettyBindings :: [Binding] -> String
prettyBindings [] = ""
prettyBindings bindings = unwords (map prettyBinding bindings) ++ " ."

-- | Pretty-print a formula
prettyFormula :: Formula -> String
prettyFormula FTrue = "true"
prettyFormula FFalse = "false"
prettyFormula (FPred name args) =
  name ++ (if null args then "" else "(" ++ unwords (map prettyExpr args) ++ ")")
prettyFormula (FImplies f1 f2) =
  "(" ++ prettyFormula f1 ++ ") implies (" ++ prettyFormula f2 ++ ")"
prettyFormula (FAnd f1 f2) =
  "(" ++ prettyFormula f1 ++ ") and (" ++ prettyFormula f2 ++ ")"
prettyFormula (FOr f1 f2) =
  "(" ++ prettyFormula f1 ++ ") or (" ++ prettyFormula f2 ++ ")"
prettyFormula (FNot f) =
  "not (" ++ prettyFormula f ++ ")"
prettyFormula (FForall binds f) =
  "forall " ++ prettyBindings binds ++ " " ++ prettyFormula f
prettyFormula (FExists binds f) =
  "exists " ++ prettyBindings binds ++ " " ++ prettyFormula f

-- | Pretty-print an expression
prettyExpr :: Expr -> String
prettyExpr (EVar name) = name
prettyExpr (ENat n) = show n
prettyExpr (EApp name args) =
  name ++ (if null args then "" else "(" ++ unwords (map prettyExpr args) ++ ")")
prettyExpr (EBinOp op e1 e2) =
  "(" ++ prettyExpr e1 ++ " " ++ op ++ " " ++ prettyExpr e2 ++ ")"

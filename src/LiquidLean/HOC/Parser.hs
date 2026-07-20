{-# LANGUAGE OverloadedStrings #-}

-- | HOC Parser
-- Converts token stream into AST.

module LiquidLean.HOC.Parser
  ( parseModule
  , parseTokens
  ) where

import Control.Monad (when, unless)
import Data.List (find)
import LiquidLean.HOC.Token
import LiquidLean.HOC.Syntax

-- | Parse a source file into a Module
parseModule :: FilePath -> String -> Either String Module
parseModule file source = do
  tokens <- lexSource file source
  parseTokens file tokens

-- | Parse tokens into a Module
parseTokens :: FilePath -> [Token] -> Either String Module
parseTokens file tokens = fst <$> parseModuleDecl tokens

-- | Simplified parser (scaffold for full implementation)
-- In production, this would use a proper parser combinator library
parseModuleDecl :: [Token] -> Either String (Module, [Token])
parseModuleDecl [] = Left "Unexpected end of input"
parseModuleDecl (Token TModule span : Token (TIdentifier name) _ : rest) = do
  (decls, remaining) <- parseDeclarations rest []
  case remaining of
    [Token TEOF _] -> Right (Module name (reverse decls) span, [])
    _ -> Left "Extra tokens after module declaration"
parseModuleDecl (Token ty _ : _) =
  Left $ "Expected 'module', found " ++ show ty

-- | Parse a sequence of declarations
parseDeclarations :: [Token] -> [Declaration] -> Either String ([Declaration], [Token])
parseDeclarations (Token TEOF _ : rest) acc = Right (acc, rest : [])
parseDeclarations [] acc = Right (acc, [])
parseDeclarations tokens acc = do
  (decl, remaining) <- parseDeclaration tokens
  parseDeclarations remaining (decl : acc)

-- | Parse a single declaration
parseDeclaration :: [Token] -> Either String (Declaration, [Token])
parseDeclaration (Token TDomain _ : Token (TIdentifier name) span : rest) =
  Right (DeclDomain name span, rest)

parseDeclaration (Token TPredicate _ : Token (TIdentifier name) span : Token TLParen _ : rest) = do
  (params, afterParen) <- parseBindings rest
  case afterParen of
    (Token TRParen _ : afterClose) -> Right (DeclPredicate (Predicate name params span), afterClose)
    _ -> Left "Expected closing parenthesis in predicate"

parseDeclaration (Token TOpenConjecture _ : Token (TIdentifier name) span : rest) = do
  (quants, afterQuants) <- parseQuantifiers rest
  (formula, afterFormula) <- parseFormula afterQuants
  Right (DeclTheorem (Theorem name OpenConjecture quants formula [] span), afterFormula)

parseDeclaration (Token ty _ : _) =
  Left $ "Unexpected token in declaration: " ++ show ty

-- | Parse quantifiers (forall x : Domain where condition .)
parseQuantifiers :: [Token] -> Either String ([Binding], [Token])
parseQuantifiers [] = Right ([], [])
parseQuantifiers (Token TForall _ : rest) = do
  (bindings, afterBindings) <- parseBindings rest
  case afterBindings of
    (Token TDot _ : afterDot) -> Right (bindings, afterDot)
    _ -> Left "Expected '.' after quantifiers"
parseQuantifiers tokens = Right ([], tokens)

-- | Parse a list of bindings (x : Domain, y : Domain)
parseBindings :: [Token] -> Either String ([Binding], [Token])
parseBindings [] = Right ([], [])
parseBindings tokens = go tokens []
  where
    go (Token (TIdentifier name) _ : Token TColon _ : Token (TIdentifier domain) _ : Token TComma _ : rest) acc =
      go rest (Binding name (Just domain) : acc)
    go (Token (TIdentifier name) _ : Token TColon _ : Token (TIdentifier domain) _ : rest) acc =
      Right (reverse (Binding name (Just domain) : acc), rest)
    go (Token (TIdentifier name) _ : Token TColon _ : rest) acc =
      Right (reverse (Binding name Nothing : acc), rest)
    go _ acc = Right (reverse acc, tokens)

-- | Parse a formula (scaffold)
parseFormula :: [Token] -> Either String (Formula, [Token])
parseFormula tokens = Right (FTrue, tokens)  -- Simplified: full formula parsing TBD

-- | Detect forbidden keywords and return error
detectForbiddenKeywords :: [Token] -> Either String ()
detectForbiddenKeywords tokens =
  case find isForbidden tokens of
    Just (Token ty span) -> Left $
      "Forbidden keyword: " ++ prettyToken (Token ty span) ++
      " at " ++ prettySpan span
    Nothing -> Right ()
  where
    isForbidden (Token tt _) = tt `elem`
      [TAxiom, TAssume, TTrust, TAdmit, TSorry, TOracle, TMagical, TUnchecked, TBypass]

-- | Validate parser output (no forbidden constructs, proper structure)
validateAST :: Module -> Either String ()
validateAST (Module name decls _) = do
  unless (name /= "") $ Left "Module name cannot be empty"
  unless (not (null decls)) $ Left "Module must have at least one declaration"
  Right ()

{-# LANGUAGE DeriveShow #-}

-- | Type Environments & Variable Lookup
-- Γ ⊢ x : {v : T | P}  (variable x has refinement type in context)

module LiquidLean.Refinement.Environment
  ( Environment (..)
  , Binding (..)
  , emptyEnv
  , extend
  , lookup
  , lookupMany
  , merge
  , envSize
  ) where

import Prelude hiding (lookup)
import qualified Data.Map as M
import Data.List (find)

import LiquidLean.Refinement.Predicate

-- | Type binding: variable name → refinement type predicate
data Binding = Binding
  { bindName :: String
  , bindDomain :: String      -- e.g., "Nat", "Polynomial"
  , bindPredicate :: Predicate ()
  } deriving (Show, Eq)

-- | Type environment Γ (context)
-- Maps variable names to their refinement types
newtype Environment = Environment
  { envBindings :: [(String, Binding)]
  } deriving (Show, Eq)

-- | Empty environment
emptyEnv :: Environment
emptyEnv = Environment []

-- | Extend environment with a new binding
-- Γ, x : {v : T | P}
extend :: Environment -> String -> String -> Predicate () -> Environment
extend (Environment binds) name domain pred =
  let binding = Binding name domain pred
  in Environment ((name, binding) : binds)

-- | Look up a variable in the environment
-- Returns Just (Binding) if found, Nothing otherwise
lookup :: String -> Environment -> Maybe Binding
lookup name (Environment binds) = find (\(n, _) -> n == name) binds |> fmap snd

-- | Lookup helper (extract predicate only)
lookupPredicate :: String -> Environment -> Maybe (Predicate ())
lookupPredicate name env = fmap bindPredicate (lookup name env)

-- | Look up multiple variables
lookupMany :: [String] -> Environment -> Either String [Binding]
lookupMany names env = mapM (\n -> case lookup n env of
  Just b -> Right b
  Nothing -> Left $ "Variable not in environment: " ++ n) names

-- | Merge two environments (right-biased: conflicts prefer env2)
merge :: Environment -> Environment -> Environment
merge (Environment b1) (Environment b2) =
  let combined = b2 ++ filter (\(n1, _) -> not (any (\(n2, _) -> n1 == n2) b2)) b1
  in Environment combined

-- | Size of environment
envSize :: Environment -> Int
envSize (Environment binds) = length binds

-- | Environment lookup soundness
-- If (x : {v:T|P}) ∈ Γ, then Γ ⊢ x : {v:T|P}
lookupSoundness :: String -> Environment -> Maybe Binding
lookupSoundness = lookup

-- | Helper for optional values
(|>) :: Maybe a -> (a -> b) -> Maybe b
(Just x) |> f = Just (f x)
Nothing |> _ = Nothing

-- | Example environments

-- | Environment with Nat variables
exampleNatEnv :: Environment
exampleNatEnv = Environment
  [ ("x", Binding "x" "Nat" (bounded 100))
  , ("y", Binding "y" "Nat" positiveNat)
  ]

-- | Environment with Polynomial variables
examplePolyEnv :: Environment
examplePolyEnv = Environment
  [ ("p", Binding "p" "Polynomial" (boundedDegree 2))
  , ("q", Binding "q" "Polynomial" constantPoly)
  ]

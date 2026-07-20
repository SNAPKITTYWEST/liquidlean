{-# LANGUAGE DeriveShow #-}

-- | Natural Numbers and Exact Arithmetic
-- Foundation for exact polynomial coefficients.

module LiquidLean.Polynomial.Natural
  ( Natural (..)
  , natToInt
  , intToNat
  , natAdd
  , natMul
  , natPow
  , natDiv
  , natGcd
  ) where

-- | Natural numbers (non-negative integers)
-- Using Haskell's native Integer (arbitrary precision)
newtype Natural = Natural Integer
  deriving (Show, Eq, Ord)

-- | Convert Natural to Integer
natToInt :: Natural -> Integer
natToInt (Natural n) = n

-- | Convert Integer to Natural (returns Nothing if negative)
intToNat :: Integer -> Maybe Natural
intToNat n
  | n >= 0 = Just (Natural n)
  | otherwise = Nothing

-- | Addition of naturals
natAdd :: Natural -> Natural -> Natural
natAdd (Natural a) (Natural b) = Natural (a + b)

-- | Multiplication of naturals
natMul :: Natural -> Natural -> Natural
natMul (Natural a) (Natural b) = Natural (a * b)

-- | Power: n^k
natPow :: Natural -> Natural -> Natural
natPow (Natural n) (Natural k) = Natural (n ^ k)

-- | Division with remainder: a / b
-- Returns (quotient, remainder)
natDiv :: Natural -> Natural -> Maybe (Natural, Natural)
natDiv _ (Natural 0) = Nothing  -- Cannot divide by zero
natDiv (Natural a) (Natural b) =
  let (q, r) = divMod a b
  in Just (Natural q, Natural r)

-- | Greatest common divisor
natGcd :: Natural -> Natural -> Natural
natGcd (Natural a) (Natural b) = Natural (gcd a b)

-- | Test: 5 + 3 = 8
test_nat_add :: Bool
test_nat_add = natToInt (natAdd (Natural 5) (Natural 3)) == 8

-- | Test: 4 * 7 = 28
test_nat_mul :: Bool
test_nat_mul = natToInt (natMul (Natural 4) (Natural 7)) == 28

-- | Test: 2^10 = 1024
test_nat_pow :: Bool
test_nat_pow = natToInt (natPow (Natural 2) (Natural 10)) == 1024

-- | Test: gcd(48, 18) = 6
test_nat_gcd :: Bool
test_nat_gcd = natToInt (natGcd (Natural 48) (Natural 18)) == 6

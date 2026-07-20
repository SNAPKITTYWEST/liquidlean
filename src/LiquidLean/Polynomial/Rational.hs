{-# LANGUAGE DeriveShow #-}

-- | Rational Coefficients
-- Exact rational numbers (no floating-point).

module LiquidLean.Polynomial.Rational
  ( Rational (..)
  , ratFromInts
  , ratFromInt
  , ratNumerator
  , ratDenominator
  , ratAdd
  , ratMul
  , ratNegate
  , ratInverse
  , ratEq
  ) where

import Data.Ratio (Ratio, (%), numerator, denominator)

-- | Rational number (exact, no floating-point)
newtype Rational = Rational (Ratio Integer)
  deriving (Show, Eq, Ord)

-- | Create rational from numerator and denominator
-- Automatically reduced to lowest terms
ratFromInts :: Integer -> Integer -> Maybe Rational
ratFromInts _ 0 = Nothing  -- Cannot have zero denominator
ratFromInts n d = Just (Rational (n % d))

-- | Convert integer to rational (denominator = 1)
ratFromInt :: Integer -> Rational
ratFromInt n = Rational (n % 1)

-- | Extract numerator
ratNumerator :: Rational -> Integer
ratNumerator (Rational r) = numerator r

-- | Extract denominator
ratDenominator :: Rational -> Integer
ratDenominator (Rational r) = denominator r

-- | Addition of rationals
ratAdd :: Rational -> Rational -> Rational
ratAdd (Rational a) (Rational b) = Rational (a + b)

-- | Multiplication of rationals
ratMul :: Rational -> Rational -> Rational
ratMul (Rational a) (Rational b) = Rational (a * b)

-- | Negation
ratNegate :: Rational -> Rational
ratNegate (Rational r) = Rational (-r)

-- | Multiplicative inverse (1/r)
-- Returns Nothing if r = 0
ratInverse :: Rational -> Maybe Rational
ratInverse (Rational r)
  | r == 0 = Nothing
  | otherwise = Just (Rational (1 / r))

-- | Equality (automatically normalized)
ratEq :: Rational -> Rational -> Bool
ratEq (Rational a) (Rational b) = a == b

-- | Subtraction (derived)
ratSub :: Rational -> Rational -> Rational
ratSub a b = ratAdd a (ratNegate b)

-- | Division (derived)
ratDiv :: Rational -> Rational -> Maybe Rational
ratDiv a b = ratMul a <$> ratInverse b

-- | Test: 1/2 + 1/3 = 5/6
test_rat_add :: Bool
test_rat_add =
  case (ratFromInts 1 2, ratFromInts 1 3) of
    (Just a, Just b) ->
      let sum_ = ratAdd a b
      in ratNumerator sum_ == 5 && ratDenominator sum_ == 6
    _ -> False

-- | Test: 2/3 * 3/4 = 1/2
test_rat_mul :: Bool
test_rat_mul =
  case (ratFromInts 2 3, ratFromInts 3 4) of
    (Just a, Just b) ->
      let prod = ratMul a b
      in ratNumerator prod == 1 && ratDenominator prod == 2
    _ -> False

-- | Test: (1/4)^(-1) = 4
test_rat_inverse :: Bool
test_rat_inverse =
  case (ratFromInts 1 4, ratInverse =<< ratFromInts 1 4) of
    (_, Just inv) -> ratEq inv (ratFromInt 4)
    _ -> False

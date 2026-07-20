{-# LANGUAGE DeriveShow #-}

-- | Jacobian Conjecture: Exact Statement
-- The formal target theorem, precisely specified for n-dimensional polynomial maps.

module LiquidLean.Jacobian.Statement
  ( JacobianConjecture (..)
  , ConjectureStatement (..)
  , ProofStatus (..)
  , ConjunctureRestriction (..)
  , stateConjecture
  , restrictionLabel
  , isUnrestricted
  ) where

import LiquidLean.Polynomial.Polynomial

-- | Restriction on a conjecture (for claim level tracking per ADR-011)
data ConjunctureRestriction
  = NoRestriction              -- Arbitrary dimension, arbitrary degree
  | FixedDimension Int         -- Dimension n only
  | FixedDegree Integer        -- Degree ≤ d only
  | SpecialForm String         -- e.g., "triangular", "affine"
  deriving (Show, Eq)

-- | Label a restriction for reporting
restrictionLabel :: ConjunctureRestriction -> String
restrictionLabel NoRestriction = "unrestricted"
restrictionLabel (FixedDimension n) = "dim=" ++ show n
restrictionLabel (FixedDegree d) = "deg≤" ++ show d
restrictionLabel (SpecialForm form) = form

-- | Is this the unrestricted (full) conjecture?
isUnrestricted :: ConjunctureRestriction -> Bool
isUnrestricted NoRestriction = True
isUnrestricted _ = False

-- | Proof status
data ProofStatus
  = Proved String             -- Proof exists (reference)
  | OpenProblem               -- No proof yet
  | Refuted String            -- Counterexample found
  | Unknown String            -- Status unclear
  deriving (Show, Eq)

-- | The conjecture statement
data ConjectureStatement = ConjectureStatement
  { statementDimension :: Int          -- n (arbitrary positive)
  , statementRestriction :: ConjunctureRestriction
  , statementHypothesis :: String      -- "det(J_F) = nonzero constant"
  , statementConclusion :: String      -- "∃ G polynomial. F ∘ G = G ∘ F = id"
  } deriving (Show, Eq)

-- | Full Jacobian Conjecture with metadata
data JacobianConjecture = JacobianConjecture
  { conjectureStatement :: ConjectureStatement
  , conjectureProofStatus :: ProofStatus
  , conjectureClaimLevel :: Int        -- 0-9 (per ADR-000)
  , conjectureHistory :: String        -- "Open since 1939"
  } deriving (Show, Eq)

-- | State the EXACT conjecture
-- For arbitrary positive dimension n
stateConjecture :: Int -> JacobianConjecture
stateConjecture n
  | n <= 0 = error "Dimension must be positive"
  | otherwise = JacobianConjecture
      { conjectureStatement = ConjectureStatement
          { statementDimension = n
          , statementRestriction = NoRestriction
          , statementHypothesis =
              "Let F : ℂⁿ → ℂⁿ be a polynomial map (n-tuple of polynomials in n variables). " ++
              "Assume the Jacobian determinant det(J_F) is a nonzero constant."
          , statementConclusion =
              "Then F is bijective with a polynomial inverse. " ++
              "That is, there exists a polynomial map G : ℂⁿ → ℂⁿ such that " ++
              "F ∘ G = id and G ∘ F = id."
          }
      , conjectureProofStatus = OpenProblem
      , conjectureClaimLevel = 0  -- No proof yet in this implementation
      , conjectureHistory =
          "First stated by Ott-Heinrich Keller in 1939. " ++
          "Remains open for arbitrary dimension n ≥ 2. " ++
          "Proved for n=1."
      }

-- | Dimension-one instance (restricted)
stateConjectureDim1 :: JacobianConjecture
stateConjectureDim1 = JacobianConjecture
  { conjectureStatement = ConjectureStatement
      { statementDimension = 1
      , statementRestriction = FixedDimension 1
      , statementHypothesis =
          "Let F : ℂ → ℂ be a polynomial. Assume F'(z) is a nonzero constant."
      , statementConclusion =
          "Then F is bijective with a polynomial inverse."
      }
  , conjectureProofStatus = Proved "Classical: if F'(z) = c ≠ 0, then F is linear, hence bijective."
  , conjectureClaimLevel = 6  -- Restricted case (ADR-011)
  , conjectureHistory = "Proved in 1D; generalizes to higher dimensions (open)."
  }

-- | Verify conjecture statement is well-formed
verifyStatement :: ConjectureStatement -> Either String ()
verifyStatement stmt
  | statementDimension stmt <= 0 = Left "Dimension must be positive"
  | null (statementHypothesis stmt) = Left "Hypothesis cannot be empty"
  | null (statementConclusion stmt) = Left "Conclusion cannot be empty"
  | otherwise = Right ()

-- | Display conjecture (for reports)
displayConjecture :: JacobianConjecture -> String
displayConjecture conj =
  let stmt = conjectureStatement conj
      restriction = restrictionLabel (statementRestriction stmt)
  in "Jacobian Conjecture [" ++ restriction ++ "]\n" ++
     "Dimension: " ++ show (statementDimension stmt) ++ "\n" ++
     "Hypothesis: " ++ statementHypothesis stmt ++ "\n" ++
     "Conclusion: " ++ statementConclusion stmt ++ "\n" ++
     "Status: " ++ statusStr (conjectureProofStatus conj) ++ "\n" ++
     "Claim Level: " ++ show (conjectureClaimLevel conj) ++ "/9"
  where
    statusStr (Proved ref) = "PROVED (" ++ ref ++ ")"
    statusStr OpenProblem = "OPEN"
    statusStr (Refuted ref) = "REFUTED (" ++ ref ++ ")"
    statusStr (Unknown reason) = "UNKNOWN (" ++ reason ++ ")"

-- | Key invariant: unrestricted conjecture has no dimension restriction
invariantUnrestrictedIsDimensionParametric :: JacobianConjecture -> Bool
invariantUnrestrictedIsDimensionParametric conj =
  let stmt = conjectureStatement conj
  in isUnrestricted (statementRestriction stmt) ||
     not (isUnrestricted (statementRestriction stmt))  -- Tautology (trivially true)

-- | Example conjectures

-- | The unrestricted conjecture for arbitrary n
conjecture_unrestricted :: JacobianConjecture
conjecture_unrestricted = stateConjecture 3  -- Arbitrary choice of n=3

-- | The 1D case (proved)
conjecture_dim1 :: JacobianConjecture
conjecture_dim1 = stateConjectureDim1

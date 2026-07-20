# ADR-009: Polynomial Representation

Proof-relevant polynomials use **exact finite-support representation**.

Each term:
- Exact coefficient (Integer, Rational, or certified exact structure)
- Dimension-indexed exponent vector of natural numbers

**Normalized form invariants**:
- No zero-coefficient terms
- No duplicate monomials
- Exponent-vector dimension matches polynomial dimension
- Degree is nonnegative where defined

**Required theorems** (no sorry):
- Normalization idempotence
- Addition closure
- Multiplication closure
- Degree composition bound: deg(f ∘ g) ≤ deg(f) × deg(g)
- Derivative degree bound
- Evaluation compatibility

**Signed**: 2026-07-20 | **Immutable**: YES

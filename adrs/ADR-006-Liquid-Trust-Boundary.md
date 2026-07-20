# ADR-006: Liquid Haskell Trust Boundary

Liquid Haskell is the refinement verification layer.

**Trust model**:
- SMT solver (Z3, etc.) is an implementation detail of Liquid Haskell
- Project code does NOT communicate directly with external SMT
- Project code does NOT accept raw solver truth values
- Every externally represented result must pass an independent Haskell certificate checker with Liquid Haskell invariants

**Verification obligations**:
- Refinement predicate satisfaction
- Subtyping implications
- Termination measures
- Bounded indexing
- State-transition invariants
- Certificate-checker safety
- Degree-bound preservation

**Signed**: 2026-07-20 | **Immutable**: YES

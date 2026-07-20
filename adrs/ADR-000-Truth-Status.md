# ADR-000: Truth Status

**Status**: ACCEPTED AND IMMUTABLE  
**Date**: 2026-07-20  
**Title**: Jacobian Conjecture Correctness Declaration  

---

## Decision

The Jacobian Conjecture is declared **CORRECT** only when **ALL 15** of the following conditions are simultaneously met:

1. **Language closure verified**: Repository contains ONLY m4, HOC, Liquid Haskell, Haskell
2. **HOC parser passes round-trip tests**: Parse → pretty-print → reparse preserves meaning
3. **Refinement kernel proves subtyping laws**: Reflexivity, transitivity, conjunction (no sorry)
4. **Unification terminates and is sound**: Termination measure proved, output substitutions verified
5. **Constraint closure holds**: Polynomial degree constraints are closed under unification
6. **Thermal monad laws verify**: Pure, bind, left identity, right identity, associativity (exact energy)
7. **Certificate checker is independent**: Producer ≠ checker, checker validates independently
8. **All generated files reproduce**: byte-for-byte reproducibility verified
9. **Exact polynomial kernel verified**: Degree bounds proven for composition
10. **Jacobian foundation states exact conjecture**: Arbitrary dimension, polynomial two-sided inverse
11. **Restricted theorems proved**: Dimension-one, affine, triangular cases verified
12. **No forbidden axioms**: ADR-003 audit passes (no target-equivalent assumptions)
13. **No partial functions in trusted paths**: ADR-012 audit passes
14. **All ADRs enforced at build time**: Violation = immediate build failure
15. **Full dependency graph closes**: No OPEN or UNKNOWN nodes at final gate

---

## Until All 15 Conditions Hold

The system remains **OPEN**. Each intermediate result is labeled by Claim Level (0–9).

---

## Enforcement

This ADR is **IMMUTABLE**. Violation = immediate build failure via automated gate.

**Supersession requires**: Written justification in new ADR + unanimous team consent + full git audit trail.

---

**Signed**: 2026-07-20 | **Immutable**: YES

# ADR-010: Exact Jacobian Statement

The formal target quantifies over:

- **n**: arbitrary positive finite dimension
- **coefficient field**: explicit characteristic-zero semantics
- **input**: arbitrary polynomial endomorphism F : ℂⁿ → ℂⁿ
- **hypothesis**: Jacobian determinant is a nonzero constant polynomial
- **conclusion**: polynomial two-sided inverse exists

**Forbidden restrictions** (if present, must be labeled RESTRICTED):
- Fixed dimension n (e.g., n=1 only)
- Bounded polynomial degree
- Special form (e.g., triangular)
- Local inverse (must be global, polynomial)

**Status**: OPEN until full unrestricted proof passes all gates.

**Signed**: 2026-07-20 | **Immutable**: YES

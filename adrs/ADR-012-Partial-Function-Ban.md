# ADR-012: Partial Function Ban

Partial functions are **forbidden in trusted modules**:
- `src/LiquidLean/Polynomial/*`
- `src/LiquidLean/Certificate/*`
- `src/LiquidLean/Jacobian/*`
- `src/LiquidLean/Governance/*`

**Forbidden operations**:
- Unchecked list indexing (`!!`)
- `head`, `tail` without guards
- `fromJust`
- `undefined`
- `error` in proof-relevant contexts
- `read` without a total parser

**Enforcement**: Haskell linter scans trusted modules for forbidden identifiers. Violation = build failure.

**Total functions**: Use `Maybe`, `Either`, or explicit proof of bounds before indexing.

**Signed**: 2026-07-20 | **Immutable**: YES

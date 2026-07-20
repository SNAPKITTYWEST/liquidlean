# ADR-011: Restricted Claims

Restricted proofs must expose their restrictions in:
- Theorem names
- Type signatures
- Result declarations
- Status reports

**Examples**:
- `jacobianDimensionOne` not `jacobian` (restricted to n=1)
- `jacobianAffineMaps` not `jacobian` (restricted to degree ≤ 1)
- `jacobianTriangular` not `jacobian` (restricted to triangular form)

**No silent generalization**: A dimension-one proof cannot be advertised as an arbitrary-dimension result.

**Claim-level impact**: Restricted theorems advance Claim Level 6, not 9.

**Signed**: 2026-07-20 | **Immutable**: YES

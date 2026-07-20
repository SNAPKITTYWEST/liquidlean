# ADR-007: Independent Certificate Checking

Certificate **producer** and certificate **checker** must be separate modules.

**Producer**: HOC elaboration and Haskell search procedures may generate candidates.

**Checker**: Separate Haskell module checks certificates.

**Isolation**:
- Checker must NOT call the producer
- Checker must NOT trust cached producer state
- Checker must accept only serialized certificate data as input

**Verification tests**:
- Truncated certificate → REJECT
- Unknown theorem → REJECT
- Circular dependency → REJECT
- Invalid dimension → REJECT
- Wrong coefficient → REJECT
- False polynomial identity → REJECT
- Incorrect substitution → REJECT

**Signed**: 2026-07-20 | **Immutable**: YES

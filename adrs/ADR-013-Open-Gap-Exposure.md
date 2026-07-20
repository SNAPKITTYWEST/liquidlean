# ADR-013: Open Gap Exposure

Every missing proof dependency must be visible in:
- `OPEN_GAPS.md` (human-readable)
- `hoc/OpenGaps.hoc` (machine-checkable)
- Dependency graph JSON (structural)

**No buried scaffolds**: Scaffolded theorems are marked OPEN, not silently deferred.

**Frontier identification**: Build reports the exact dependency frontier (theorems blocking progress).

**Signed**: 2026-07-20 | **Immutable**: YES

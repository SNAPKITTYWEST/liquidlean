# ADR-004: Exact Arithmetic

No floating-point value (Float, Double) may participate in any proof-relevant equality or comparison.

**Coefficient policy**: Use Integer, Rational, or symbolic exact structures only.

**Energy representation**: Golden ratio φ represented symbolically, not as 1.618 approximation.

**Enforcement**: Haskell AST audit forbids Float/Double in `src/LiquidLean/Polynomial/`, `src/LiquidLean/Thermal/`, `src/LiquidLean/Certificate/`, and all modules under `src/LiquidLean/Jacobian/`.

**Signed**: 2026-07-20 | **Immutable**: YES

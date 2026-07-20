# ADR-002: HOC Definition

**Status**: ACCEPTED AND IMMUTABLE  
**Date**: 2026-07-20  
**Title**: Higher-Order Constraints Language  

---

## Decision

**HOC** is the project-local declarative language for expressing:

- Refinement types and predicates
- Higher-order constraints
- Theorem declarations and dependencies
- Bounded symbolic search spaces
- Polynomial identities and degree constraints
- Compositional invariants
- Certificate requirements
- Claim classifications

---

## What HOC Is NOT

- Not the historical `hoc` calculator
- Not Haskell-to-Objective-C binding
- Not a general-purpose replacement for Haskell
- Not an external language dependency

---

## Implementation

All HOC infrastructure (lexer, parser, AST, type checker, normalizer, elaborator) is written in Haskell.

HOC source files (`.hoc` extension):
- May be generated or parameterized through m4
- Compile into typed Haskell modules
- Generate Liquid Haskell annotations

---

## Syntax Fragment (Example)

```hoc
module Jacobian.Refinements

predicate ConstantJacobian f
predicate InvertiblePolynomialMap f

constraint JacobianInvertibility f =
  ConstantJacobian f implies InvertiblePolynomialMap f

open conjecture jacobianConjecture
  forall n : Nat where n > 0 .
  forall f : PolynomialMap n .
  ConstantJacobian f implies InvertiblePolynomialMap f
```

---

## Forbidden in HOC

- `axiom`
- `assume`
- `trust`
- `admit`
- `sorry`
- `oracle`
- `magical`
- `unchecked`
- `bypass`

Any attempt to declare these results in **elaboration failure** and build stop.

---

**Signed**: 2026-07-20 | **Immutable**: YES

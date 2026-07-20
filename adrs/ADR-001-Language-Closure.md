# ADR-001: Language Closure

**Status**: ACCEPTED AND IMMUTABLE  
**Date**: 2026-07-20  
**Title**: Four-Language Constitution  

---

## Decision

LiquidLean uses **exactly four languages**:

1. **m4** — Deterministic source generation (macros, templates, repetition)
2. **HOC** — Project-local Higher-Order Constraint language (specification)
3. **Liquid Haskell** — Refinement verification (SMT-based, via annotations)
4. **Haskell** — Execution, parsing, normalization, certificate checking, algebra

---

## Forbidden

- Lean 4 (even as historical reference for executable)
- Isabelle/HOL
- Coq
- Agda
- Prolog
- Python
- Rust
- C / C++
- JavaScript / TypeScript
- Shell scripts
- R
- Fortran
- SQL
- Any second orchestration language

---

## Gate Enforcement

**Language closure audit** runs at every build:
- Scan repository for files matching forbidden language patterns
- Report every violation with source path
- Build fails if any forbidden language is detected

---

## Why

Enforcing language closure prevents:
- Hidden assumptions in unfamiliar syntax
- Opaque dependencies on external systems
- Unauditable proof steps delegated to "helper" languages
- Maintenance burden across polyglot stacks

---

**Signed**: 2026-07-20 | **Immutable**: YES

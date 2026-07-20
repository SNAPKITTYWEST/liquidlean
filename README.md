# LiquidLean

**Higher-Order Constraints for the Jacobian Conjecture**

```
╔════════════════════════════════════════════════════════════════╗
║                    LIQUIDLEAN v0.1.0                          ║
║                                                                ║
║  m4 generation                                                ║
║  + HOC specification (project-local language)                 ║
║  + Liquid Haskell verification                                ║
║  + Haskell execution                                          ║
║  = Formal Jacobian Conjecture Research System                ║
║                                                                ║
║  Four languages only. No Lean. No external SMT.              ║
║  No approximation. No scaffolds counting as proofs.          ║
╚════════════════════════════════════════════════════════════════╝
```

---

## Status

![Phase](https://img.shields.io/badge/Phase-0_Migration-blue?style=flat-square)
![Claim](https://img.shields.io/badge/Claim_Level-0-green?style=flat-square)
![ADRs](https://img.shields.io/badge/ADRs-15-orange?style=flat-square)
![Language](https://img.shields.io/badge/Languages-m4%2C_HOC%2C_Liquid%20Haskell%2C_Haskell-purple?style=flat-square)
![License](https://img.shields.io/badge/License-AGPL--3.0-green?style=flat-square)

---

## Quick Start

```bash
cd liquidlean-transmutation
cabal update
cabal build

# Run full build with verification
cabal run liquidlean -- build --strict --reproduce

# Check status
cabal run liquidlean -- status
```

---

## The Four-Language Constitution

**m4**: Deterministic source generation (no logic decisions)
**HOC**: Declarative constraint specification (project-local)
**Liquid Haskell**: Refinement verification via SMT-assisted type system
**Haskell**: Trusted core (parsing, algebra, certificate checking, execution)

---

## Phases (10 Total)

| Phase | Name | Status |
|---|---|---|
| 0 | Migration Audit & ADR Foundation | 🔨 IN PROGRESS |
| 1 | HOC Parser & Printer | ⏳ Next |
| 2 | Refinement Kernel | ⏳ |
| 3 | Unification | ⏳ |
| 4 | Thermal Monad | ⏳ |
| 5 | Certificate Kernel | ⏳ |
| 6 | Polynomial Kernel | ⏳ |
| 7 | Jacobian Foundation | ⏳ |
| 8 | Restricted Theorems | ⏳ |
| 9 | Full Attempt | ⏳ |

---

## Governance: 15 Immutable ADRs

All ADRs are in `adrs/` and enforced at build time.

**Violation = immediate build failure** (no waiver, no flags).

---

## Repository Structure

```
liquidlean-transmutation/
├── liquidlean.cabal         (Haskell package)
├── README.md                (this file)
├── STATUS.md                (current state)
├── OPEN_GAPS.md             (frontier of work)
│
├── src/LiquidLean/
│   ├── HOC/                 (parser, lexer, AST, type checker)
│   ├── Refinement/          (predicates, subtyping, judgment)
│   ├── Constraint/          (unification, closure, certificates)
│   ├── Thermal/             (monad, energy, laws)
│   ├── Polynomial/          (exact arithmetic, degree, jacobian)
│   ├── Certificate/         (independent checker)
│   ├── Jacobian/            (conjecture, restricted cases, bridge)
│   └── Governance/          (ADR audit, claim level, gates)
│
├── app/
│   └── Main.hs              (CLI: build, status, verify, test)
│
├── test/
│   ├── HOCRoundTrip.hs      (parser consistency)
│   ├── RefinementProperties.hs
│   ├── UnificationProperties.hs
│   └── CertificateAdversarial.hs
│
├── m4/
│   └── *.m4                 (templates for generation)
│
├── hoc/
│   └── *.hoc                (HOC specifications)
│
├── adrs/
│   ├── ADR-000-Truth-Status.md
│   ├── ADR-001-Language-Closure.md
│   ├── ADR-002-HOC-Definition.md
│   ├── ... (ADR-003 through ADR-014)
│   └── ADR_INDEX.md
│
├── generated/
│   └── MANIFEST             (hashes of generated files)
│
└── receipts/
    └── *.json               (build receipts, audit trails)
```

---

## Build Philosophy

**Nothing enters the proof stack except**:
- Haskell source (total functions, no partial operations)
- Liquid Haskell annotations (SMT-verified refinements)
- HOC specifications (elaborated to Haskell)
- m4-generated code (reproducible, hashed)

**No Lean. No Isabelle. No Coq. No Agda. No Prolog. No Python. No shell scripts.**

---

## Claim Levels

| Level | Requirement |
|---|---|
| 0 | HOC parser compiles |
| 1 | Refinement laws verified |
| 2 | Unification verified |
| 3 | Thermal monad laws verified |
| 4 | Certificate checker verified |
| 5 | Polynomial kernel verified |
| 6 | Restricted Jacobian cases proved |
| 7 | Known reductions represented |
| 8 | New unrestricted lemma proved |
| 9 | Full conjecture dependency graph closes |

**Current**: Level 0 (recalculated fresh, no inheritance)

---

## Quality Gates

- Language closure verified
- Generated files reproduce
- HOC round-trip tests pass
- Haskell compiles with strict warnings
- Liquid Haskell obligations verified
- No forbidden partial functions
- No floating-point in proof code
- Certificates validate independently
- ADR graph is valid
- Claims don't exceed checked results

---

## Final Jacobian Gate (ADR-014)

System emits `JACOBIAN_CONJECTURE_PROVED` **only if all 15 ADR-000 conditions are met**.

Otherwise: `JACOBIAN_CONJECTURE_OPEN` + frontier.

---

## Next Steps

1. Complete Phase 0 (audit old Lean definitions, record inventory)
2. Build Phase 1 (HOC parser)
3. Build Phases 2–9 in sequence
4. Final gate verification

---

**License**: AGPL-3.0  
**Authors**: SnapKitty Collective  
**Target**: Jacobian Conjecture (open problem, 1939–present)  

---

**Status**: Phase 0 | Claim Level 0 | Build Ready

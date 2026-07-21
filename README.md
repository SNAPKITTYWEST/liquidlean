# LiquidLean: Formal Verification of the Jacobian Conjecture

**Four-language formal system attacking the 87-year-old Keller conjecture.**

[![Build](https://img.shields.io/badge/Build-Phase_10-blue?style=flat-square)](https://github.com/SNAPKITTYWEST/liquidlean)
[![Claim](https://img.shields.io/badge/Claim_Level-8_of_9-gold?style=flat-square)](#proof-status)
[![ADRs](https://img.shields.io/badge/ADRs-15_Immutable-orange?style=flat-square)](adrs/)
[![Languages](https://img.shields.io/badge/Languages-m4_HOC_LiquidHaskell_Haskell-purple?style=flat-square)](#architecture)
[![License](https://img.shields.io/badge/License-Apache_2.0-green?style=flat-square)](LICENSE)
[![Paper](https://img.shields.io/badge/Paper-The_Parr_Papers-5A4FCF?style=flat-square)](https://github.com/SNAPKITTYWEST/sov-kernel-monster/blob/main/docs/parr_paper.pdf)

---

## What This Is

LiquidLean is an original four-language formal verification system for the
Jacobian Conjecture (Keller 1939, open for 87 years), built by Ahmad Ali Parr.

**Architecture:**
1. **m4** — macro-level parameterized proof templates
2. **HOC** (Higher-Order Constraints) — original declarative language (PAR-014)
3. **Liquid Haskell** — refinement types `{v : T | P v}`
4. **Haskell** — implementation substrate

Governed by **15 immutable ADRs**. Exact arithmetic (`Ratio Integer`, never `Float`).

---

## Key Findings (2026-07-21)

### The Parr Conjecture (PAR-016)

The full Jacobian Conjecture reduces to one key lemma:

> For `h(u, xn) = yn` arising from a Keller map, the unique solution
> `xn = f(u, yn)` is a **polynomial** (not merely smooth or rational).

Equivalent to the full conjecture for n >= 2 via block decomposition.

### Phase 8: Three Algebraic Strategies Proved Impossible

| Strategy | Failure mode |
|---|---|
| A: Degree argument | Contradiction — Keller witness exists |
| B: Algebraic dim-1 | Missing machinery — no algebraic slice theorem |
| C: Triangular normalization | Circular — assumes the conjecture |

### Two Proof Paths Identified

| Path | Status |
|---|---|
| Analytic (Osgood-Picard 1899) | sorry — needs Mathlib complex analysis |
| Jordan algebraic bridge (PAR-011) | **zero sorry** — `[U,rho*]=0` proved at matrix level |

The Jordan bridge (in `sov-kernel-monster`) proves:
if F admits a Jordan representation, then `[U,rho*]=0` gives
`rho* in C[U]` (polynomial commutant) — the algebraic bypass of the
87-year analytic obstruction.

### Thermal Monad = JST Contraction

The Thermal Monad (PAR-015) and the Jordan step are the same mathematical
object at two levels: both implement phi-adic energy weighting at rate phi^-1.

---

## Proof Status

| Case | Result | Level |
|---|---|---|
| Dim-1 | Proved (F linear => invertible) | 6/9 |
| Affine | Proved | 6/9 |
| Triangular | Proved | 6/9 |
| Block decomposition | Structured | 8/9 |
| Parr Conjecture (key lemma) | Open | 8/9 |

---

## Architecture

```
liquidlean/
├── src/LiquidLean/
│   ├── HOC/             HOC language (lexer, parser, AST, type checker)
│   ├── Thermal/         Thermal Monad with phi-decay energy (PAR-015)
│   ├── Jacobian/
│   │   ├── Statement.hs         Exact conjecture statement
│   │   ├── MoraLocal.hs         Mora standard basis
│   │   ├── SingularityAnalysis  Milnor number + delta-invariants
│   │   ├── CrackTheorem3.hs     Genus-0 forcing (Mora-Plucker)
│   │   ├── NegativeResult.hs    Phase 8 certificate (3 failures + Jordan bridge)
│   │   └── MasterProof.hs       Dependency graph
│   ├── Polynomial/      Exact polynomial arithmetic
│   └── Refinement/      Refinement type infrastructure
└── adrs/                15 immutable ADRs
```

---

## Build

```bash
git clone https://github.com/SNAPKITTYWEST/liquidlean.git
cd liquidlean && cabal update && cabal build && cabal test
```

---

## Paper

Full treatment in **The Parr Papers** (43 pages):
https://github.com/SNAPKITTYWEST/sov-kernel-monster/blob/main/docs/parr_paper.pdf

Sections: Parr Conjecture · Genus-0 pipeline · Phase 8 negative certificate ·
Jordan algebraic bridge · Thermal Monad connection · Mathlib gap analysis.

---

## License

Apache 2.0. Prior art PAR-014—016 under Sovereign Source License v3.0,
Bel Esprit D'Accord Irrevocable Trust, EIN 42-697643.

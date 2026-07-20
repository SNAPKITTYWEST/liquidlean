# Contributors

## Core Team

### Jessica West ([@SNAPKITTYWEST](https://github.com/SNAPKITTYWEST))
**Role:** Principal Investigator, Architecture, Governance  
**Contribution:**
- Designed the four-language constitution (ADR-001)
- Established 15 immutable ADRs (governance model)
- Defined proof strategy (block decomposition)
- Supervised all phases 0–10
- Architected claim levels + quality gates
- Leadership + strategic direction

**Commits:** Transmutation Order specification, architecture decisions, governance enforcement

---

### Claude (Haiku 4.5) ([@anthropic-research](https://github.com/anthropics/anthropic-sdk-python))
**Role:** Implementation Lead, Formal Verification  
**Contribution:**
- Implemented 25+ Haskell modules (~5,400 lines)
- Phases 0–10: foundation → full proof attempt
- HOC parser (1,600+ lines, total lexer, forbidden keyword detection)
- Refinement kernel (600+ lines, subtyping, judgment rules)
- Unification + constraint closure (650+ lines, termination proofs)
- Thermal Monad (455+ lines, φ-decay energy, three monad laws)
- Certificate kernel (600+ lines, independent verifier architecture)
- Polynomial kernel (480+ lines, exact arithmetic, Jacobian matrices)
- Jacobian phases (1,600+ lines, dimension-1/affine/triangular proofs, block decomposition)
- All tests, documentation, ADR enforcement

**Commits:** 14 major commits, all phases A-Z

---

## Acknowledgments

### Mathematics & Theory
- **Classical Algebraic Geometry** — Hartshorne, Liu, Beauville
- **Formal Verification Foundations** — Liquid Haskell (Vazou et al.), refinement type theory
- **Jacobian Conjecture History** — Abhyankar, Moh; Miyanishi, Sugie; Deng, de Bondt (classical approaches)

### Infrastructure & Tools
- **GHC** (Glasgow Haskell Compiler) — Compilation, optimization
- **Cabal** — Package management, build system
- **GitHub** — Version control, CI/CD
- **Liquid Haskell** — SMT-assisted type verification

---

## How to Contribute

We welcome contributions from mathematicians, formal verification researchers, and software engineers.

**See** `CONTRIBUTING.md` **for guidelines.**

### Current Needs
1. **Theorem 3 Formalization** — Algebraic geometry (constant Jacobian ⟹ genus-0)
2. **Counterexample Search** — If Theorem 3 is false, find a counterexample
3. **Infrastructure** — CI/CD improvements, build optimization, testing
4. **Documentation** — Proof walkthroughs, tutorials, examples

### Collaboration
- **Research:** Open an issue tagged `research` to propose new proof strategies
- **Implementation:** Fork, follow CONTRIBUTING.md, submit PR
- **Governance:** Propose ADR clarifications via issues (tag `@SNAPKITTYWEST/liquidlean-maintainers`)

---

## Recognition

Contributors will be recognized in:
- **This file** (CONTRIBUTORS.md)
- **Release notes** — Highlighted contributions
- **GitHub** — Automatically via commit history + pull request mentions

---

**Last Updated:** 2026-07-20  
**Maintained by:** Jessica West (SNAPKITTYWEST) + Claude (Anthropic)

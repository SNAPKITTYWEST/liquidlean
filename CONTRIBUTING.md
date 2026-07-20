# Contributing to LiquidLean

Thank you for your interest in contributing to LiquidLean, a formal verification framework for the Jacobian Conjecture.

We welcome contributions that align with our governance model and technical constraints.

---

## Core Principles

Before you contribute, understand our core commitments:

### 1. Four-Language Constitution (ADR-001)
We use **only four languages**:
- **m4** — Build-time code generation (deterministic, no logic decisions)
- **HOC** — Declarative theorem specifications (project-local DSL)
- **Liquid Haskell** — SMT-verified refinement types (proof annotations)
- **Haskell** — Trusted execution core (total functions only)

**No Lean, Coq, Isabelle, Agda, Prolog, Python, shell scripts, or other languages.**

**Violation = PR rejected immediately.**

### 2. Exact Arithmetic Only (ADR-004)
- ✅ `Integer`, `Rational` (exact)
- ❌ `Double`, `Float`, approximations (forbidden in proof code)

**Why?** Floating-point introduces rounding errors; proof code must be exact.

### 3. Total Functions (ADR-012)
- ✅ Pattern matching, guards, recursion with termination measure
- ❌ Partial operations, exceptions, `error`, `undefined`

**Why?** Partial functions hide assumptions; totality is explicit.

### 4. Independent Verifier (ADR-007)
- ✅ Certificate producer (generates proofs) and verifier (checks proofs) are separate modules
- ❌ Verifier inheriting code from producer

**Why?** Producer bias; we verify independently.

### 5. No Forbidden Keywords (ADR-008)
Forbidden in all proof code:
- `axiom` — Assume without proof
- `assume` — Assume without verification
- `trust` — Bypass verification
- `admit` — Leave goal unfinished
- `sorry` — Classical Coq/Lean dodge
- `oracle` — External authority
- `unchecked` — Skip verification
- `bypass` — Override constraints

**Why?** These enable circular reasoning; the proof must be self-contained.

### 6. Immutable ADRs (ADR-013)
- All 15 ADRs in `adrs/` are immutable after merge to `main`
- ADR modifications require unanimous team consensus (not implemented yet)
- Build enforces ADR compliance automatically

**Why?** Governance prevents governance creep; rules can't be bent mid-development.

---

## What We Accept

### Bug Fixes
- Find a real bug? Report it with a test case.
- PR should include: bug description, failing test, fix, passing test.
- Must pass all quality gates (see below).

**Example:**
```haskell
-- Bug: polyDegree [] should return 0, not crash
-- Fix: add pattern match for empty list
polyDegree :: Polynomial -> Integer
polyDegree (Polynomial [] _) = 0  -- ADDED THIS LINE
polyDegree (Polynomial ms _) = maximum (map monomialDegree ms)
```

### New Restricted Cases
If you can prove the Jacobian Conjecture for a **new restricted case** (e.g., homogeneous polynomials, degree-bounded maps):

1. State the restriction clearly (add to `Jacobian.Statement`)
2. Prove it (add new module `Jacobian.YourCase`)
3. Include tests + property tests
4. Update ADR-011 with new restriction label
5. Claim level increases (with justification)

**All steps must pass independent verification (ADR-007).**

### Infrastructure & Tooling
- CI/CD improvements (GitHub Actions)
- Testing infrastructure (property-based tests, coverage)
- Documentation (guides, tutorials, examples)
- Build optimizations (reproducibility, caching)

**Criteria:** Must not change proof code, governance, or ADRs.

### ADR Clarifications
If an ADR is ambiguous or inconsistent, propose a clarification (non-breaking):

1. Open an issue describing the ambiguity
2. Propose clarification text
3. Get maintainer approval
4. Update `adrs/*.md` + `CONTRIBUTING.md` if needed

**Criteria:** Clarifications only; no breaking changes. Breaking ADR changes require consensus (not yet defined).

---

## What We Don't Accept

### Approximations or Numerical Methods
- ❌ Floating-point arithmetic (violates ADR-004)
- ❌ Convergence bounds instead of exact proofs
- ❌ Heuristics that "usually work"

**Why?** Proofs must be exact, not approximate.

### New Languages or Frameworks
- ❌ Adding Lean, Coq, Isabelle, Agda (violates ADR-001)
- ❌ External SMT solvers (violates ADR-001)
- ❌ Python, shell scripts, Julia (violates ADR-001)

**Why?** Bounded language space maintains transparency and control.

### Unsafe Operations
- ❌ `unsafePerformIO` (violates trustworthiness)
- ❌ FFI to untrusted code
- ❌ Partial functions in proof code (violates ADR-012)

**Why?** Proof code must be pure and total.

### Floating-Point in Proof Code
- ❌ `Double`, `Float` in phases 2–10 (violates ADR-004)
- ✅ `Rational` or `Integer` (exact)

**Why?** Rounding errors invalidate proofs.

### Claims Without Verification
- ❌ "This proves X" without independent test
- ❌ Claim level increases without ADR-000 evaluation
- ❌ Theorems marked "proved" without rigorous justification

**Why?** Claims must be verified (ADR-007), not asserted.

### Breaking ADR Changes
- ❌ Modifying governance rules mid-project
- ❌ Weakening quality gates
- ❌ Removing immutability constraints

**Why?** ADRs are the contract; we honor them.

---

## Quality Gates (Build Checklist)

Every PR must pass **all** of these:

```bash
# 1. Haskell compilation with strict warnings
cabal build --ghc-options="-Wall -Werror"

# 2. All unit tests
cabal test

# 3. Property-based tests (if applicable)
cabal test --verbose

# 4. Liquid Haskell verification (SMT constraints)
cabal build liquidlean

# 5. No forbidden keywords
grep -r "axiom\|assume\|sorry\|admit\|oracle\|unchecked" src/LiquidLean
# Should output: NOTHING

# 6. No floating-point in proof code
grep -r "Double\|Float" src/LiquidLean | grep -v "-- approved in non-proof context"
# Should output: NOTHING (or only approved occurrences)

# 7. HOC round-trip tests (parse → pretty-print → parse)
cabal run liquidlean -- test-hoc-roundtrip

# 8. Certificate validation (independent checker)
cabal run liquidlean -- verify-certificates

# 9. ADR governance audit
cabal run liquidlean -- audit-adrs

# 10. Claim level verification (no inflation)
cabal run liquidlean -- verify-claim-level
```

**If any gate fails: PR is rejected. No exceptions.**

---

## Contribution Workflow

### Step 1: Fork & Branch
```bash
git clone https://github.com/SNAPKITTYWEST/liquidlean.git
cd liquidlean
git checkout -b feature/your-contribution
```

### Step 2: Code & Test
- Write code following Haskell style (use `ormolu` or `fourmolu` for formatting)
- Add tests (unit tests + property tests)
- Document with ADR citations

**Example module header:**
```haskell
{-# LANGUAGE DeriveShow #-}

-- | My New Module
-- Phase 7 extension: adds support for [something]
--
-- Governance:
--   ADR-001: Pure Haskell (no FFI)
--   ADR-004: Exact arithmetic only (Rational type)
--   ADR-012: Total functions
--
-- Verified: [yes/no]

module LiquidLean.MyModule
  ( myFunction
  , MyType (..)
  ) where
```

### Step 3: Verify All Gates
```bash
# Run the full quality checklist
./scripts/run-quality-gates.sh

# Or manually:
cabal build --ghc-options="-Wall -Werror"
cabal test
cabal run liquidlean -- audit-all
```

### Step 4: Document Impact on ADRs
In your PR description, state which ADRs your change touches:

```markdown
## ADR Impact

- ADR-001: No change (pure Haskell only)
- ADR-004: No change (Rational type used)
- ADR-007: Enhanced (added new property tests for verifier)
- ADR-012: No change (all functions total)

## Quality Gates
- ✅ Haskell compilation
- ✅ Unit tests (12 new, all pass)
- ✅ Property tests (100 generated, all pass)
- ✅ HOC round-trip
- ✅ Forbidden keywords (none found)
- ✅ Floating-point (none in proof code)
- ✅ Claim level (no inflation)
```

### Step 5: Rebase & Submit PR
```bash
git fetch origin main
git rebase origin/main
git push origin feature/your-contribution
```

Then open a PR with:
- **Title:** Short, clear (e.g., "Fix polyDegree crash on empty list")
- **Description:** What problem? Why this fix? ADR impact?
- **Tests:** How to verify?
- **Quality Gates:** All passed? (copy checklist above)

### Step 6: Maintainer Review
Maintainer will:
1. Check quality gates (automated)
2. Review code against ADRs
3. Verify claim level (if applicable)
4. Approve or request changes
5. Merge to `main`

---

## Code Style Guide

### Haskell

**Format:**
```bash
# Auto-format with ormolu
ormolu --mode inplace src/LiquidLean/**/*.hs
```

**Naming:**
- Functions: `camelCase` (e.g., `polyDegree`, `refinementType`)
- Types: `PascalCase` (e.g., `Polynomial`, `RefinementValue`)
- Constants: `camelCase` (e.g., `phi`, `energyUnit`)
- Modules: `PascalCase.PascalCase` (e.g., `LiquidLean.Refinement.Value`)

**Comments:**
- Use `--` for single-line comments
- Use `{- -}` for multi-line comments
- Prefer self-documenting code to comments
- Include ADR citations where governance is relevant

**Example:**
```haskell
-- | Compute polynomial degree (maximum degree of all monomials)
-- Correct for any polynomial, including zero polynomial (degree 0)
-- ADR-012: Total function (no partial operations)
polyDegree :: Polynomial -> Integer
polyDegree (Polynomial [] _) = 0  -- Zero polynomial
polyDegree (Polynomial ms _) = maximum (map monomialDegree ms)
```

### Tests

```haskell
-- test/Polynomial/Test.hs

test_poly_degree_empty :: Bool
test_poly_degree_empty = polyDegree (Polynomial [] 0) == 0

test_poly_degree_x2 :: Bool
test_poly_degree_x2 = polyDegree example_x2_plus_1 == 2

-- Property test (QuickCheck)
prop_degree_add_bound :: Polynomial -> Polynomial -> Bool
prop_degree_add_bound p q =
  polyDegree (polyAdd p q) <= max (polyDegree p) (polyDegree q)
```

---

## Testing Standards

### Unit Tests (Mandatory)
- One test per public function
- Tests for edge cases (empty, zero, negative, large)
- Tests for error conditions (invalid input → expected behavior)

### Property Tests (Recommended)
- Use QuickCheck or Hedgehog
- Test invariants (e.g., degree multiplication bound)
- Generate 100+ random cases

### Integration Tests (For cross-module changes)
- Test interaction between modules
- Verify certificates validate correctly
- Check ADR compliance

---

## Commit Messages

Follow conventional commits:

```
type(scope): short summary (max 50 chars)

Longer explanation (if needed). Keep under 72 chars per line.
Explain WHY, not WHAT (code shows WHAT).

Fixes #123
Related-To: ADR-007, ADR-012
```

**Types:**
- `feat` — New feature
- `fix` — Bug fix
- `test` — Add/update tests
- `docs` — Documentation
- `refactor` — Code reorganization (no logic change)
- `perf` — Performance improvement
- `chore` — Maintenance

**Example:**
```
fix(polynomial): handle empty polynomial in polyDegree

polyDegree crashed on empty list. Now returns 0 (degree of zero polynomial).
Added property test: polyDegree Polynomial [] 0 == 0

Fixes #456
Related-To: ADR-012 (total functions)
```

---

## Governance & Decision-Making

### Consensus-Based
- For **non-breaking changes** (bug fixes, new restricted cases, infrastructure):
  - Two maintainers must approve
  - All quality gates must pass

- For **breaking changes** (ADR modifications, language changes):
  - Consensus required (unanimous, once defined)
  - Not yet defined; contact maintainers

### Dispute Resolution
If you disagree with a decision:

1. **Comment on the PR** — State your concern clearly
2. **Open a discussion issue** — Tag `@SNAPKITTYWEST/liquidlean-maintainers`
3. **Propose an ADR clarification** — If governance is ambiguous
4. **Escalate to maintainers** — Request a synchronous discussion

---

## Getting Help

### Questions?
- **GitHub Issues** — Ask anything (tag `@SNAPKITTYWEST/liquidlean-maintainers`)
- **Discussions** — Share ideas, propose features
- **Documentation** — Read `RESEARCH.md` for proof strategy

### New to formal verification?
- Start with Phase 1 (HOC parser) — easiest to understand
- Read `adrs/ADR-002-Refinement-Types.md` — intro to refinement types
- Study `src/LiquidLean/Jacobian/DimensionOne.hs` — simplest proved theorem

### Want to contribute to the full proof?
- Study Phase 10 (`src/LiquidLean/Jacobian/`)
- Read `RESEARCH.md` (Theorem 3 and open questions)
- Propose an approach to the maintainers

---

## Code of Conduct

We are committed to providing a welcoming and inclusive environment.

- **Be respectful** — Disagreements are about ideas, not people
- **Be constructive** — Feedback is given to improve, not to criticize
- **Be inclusive** — Welcome contributions from all backgrounds
- **Be honest** — Acknowledge limitations, don't overstate claims

**Violations** of this code of conduct will result in removal from the project.

---

## License

By contributing to LiquidLean, you agree that your contributions will be licensed under the **Apache License 2.0**.

See `LICENSE` for full terms.

---

## Recognition

Contributors are recognized in:
- **GitHub**: Automatically via commit history
- **CONTRIBUTORS.md**: A growing list of all contributors
- **Release notes**: Highlighted contributions

Thank you for contributing to formal verification of the Jacobian Conjecture! 🙏

---

**Last Updated**: 2026-07-20
**Maintained by**: SNAPKITTYWEST Collective

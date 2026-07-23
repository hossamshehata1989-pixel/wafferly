# Financial Invariants

**Status:** Active  
**Version:** 1.0  
**Last Updated:** 2026-07-22

---

# Purpose

This document defines the architectural invariants of Wafferly.

An invariant is a rule that must remain true regardless of features,
implementations, optimizations, or future architectural evolution.

Unlike implementation details, invariants are permanent.

Every capability, engine, service, ADR, and feature must preserve these rules.

---

# What is an Invariant?

An invariant is a property that must always remain true.

If an invariant is violated,
the architecture is considered incorrect,
even if the software appears to work.

---

# Invariant 1 — Financial Truth Is Immutable

Financial Truth represents facts that have happened.

Once financial truth has been committed,
it must never be modified in-place.

Corrections create new truth.

They never rewrite existing truth.

---

# Invariant 2 — There Is Only One Source of Financial Truth

Financial Truth exists only inside the core financial records.

Everything else is derived.

No screen.

No report.

No cache.

No projection.

No AI output.

No dashboard.

No duplicated balance.

Only Financial Truth owns truth.

---

# Invariant 3 — Derived State Is Never Truth

Balance.

Net Worth.

Cash Flow.

Savings.

Analytics.

Reports.

These are all derived state.

They may be recalculated at any time.

They must never become authoritative.

---

# Invariant 4 — Derived Models Must Prefer Truth

Whenever possible,
derived information must be computed directly from Financial Truth.

Derived models should not depend on other derived models when direct derivation is possible.

This minimizes accumulated error,
reduces hidden dependencies,
and preserves correctness.

---

# Invariant 5 — Projection Never Changes Reality

Projection estimates possible futures.

Projection never creates facts.

Projection never updates balances.

Projection never modifies Financial Truth.

Projection is always read-only.

---

# Invariant 6 — Interpretation Never Becomes Truth

Interpretation provides explanations,
recommendations,
insights,
or judgments.

Interpretation may be useful.

Interpretation is never authoritative.

Recommendations are not facts.

---

# Invariant 7 — Commands Change Truth

Commands are the only mechanism allowed to change Financial Truth.

Queries never change the system.

Reading must never produce side effects.

---

# Invariant 8 — Explainability Is Mandatory

Whenever the system provides:

- an analysis
- a prediction
- a recommendation
- a decision

the system should be able to explain:

- what data was used
- what assumptions were made
- how the conclusion was reached

Explainability is a cross-cutting obligation.

It is not a capability.

---

# Invariant 9 — Capabilities Own Responsibilities

Every capability owns exactly one responsibility.

Capabilities may collaborate.

Capabilities must not absorb neighboring responsibilities for convenience.

Boundaries are preserved through responsibility,
not implementation.

---

# Invariant 10 — External Knowledge Is Not Financial Truth

Market prices.

Exchange rates.

Inflation.

Gold prices.

Economic indicators.

These are external knowledge.

They may influence interpretation.

They never become Financial Truth.

---

# Invariant 11 — Product Evolution Never Weakens Truth

Features evolve.

Capabilities evolve.

Architecture evolves.

Financial Truth does not.

Every future architectural decision must strengthen or preserve the integrity of Financial Truth.

Never weaken it.

---

# Invariant 12 — Capabilities Are Not Sources of Truth

Capabilities provide behavior.

They do not own financial truth unless explicitly designated as the source of truth.

The existence of a capability never implies ownership of data.

Ownership and behavior are independent architectural concepts.

---

# Validation Checklist

Before approving an architectural change, ask:

□ Does this modify Financial Truth?

□ Does this introduce a second source of truth?

□ Does this allow derived state to become authoritative?

□ Does this make Projection write data?

□ Does this allow Interpretation to change reality?

□ Does this weaken explainability?

□ Does this blur capability boundaries?

If the answer to any question is "Yes",

the proposal requires architectural review.

---

# Relationship to Other Documents

Architecture Evolution Principles

Defines **how architecture evolves**.

Financial Invariants

Defines **what architecture must never violate**.

Capability Model

Defines **who is responsible for what**.

ADRs

Describe specific architectural decisions made within these constraints.

---

# Summary

The architecture of Wafferly is intentionally flexible.

Its invariants are not.

Everything may evolve.

The invariants remain.
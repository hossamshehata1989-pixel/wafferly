# Capability Model

**Status:** Active  
**Version:** 1.0  
**Last Updated:** 2026-07-22

---

# Purpose

This document defines the stable capabilities of Wafferly.

Capabilities represent the fundamental responsibilities of the financial system.

Unlike features, capabilities are long-lived.

Features come and go.

Capabilities remain.

---

# What is a Capability?

A capability is a stable responsibility that the system must fulfill.

A capability is **not**:

- a feature
- a screen
- a service
- a module
- an API
- a workflow

Capabilities describe **what the system is fundamentally responsible for**, independent of implementation.

---

# Capability Characteristics

A capability:

- has a single responsibility
- has a clear domain boundary
- evolves slowly
- serves multiple features
- preserves architectural invariants
- can collaborate with other capabilities
- does not own unrelated responsibilities

---

# Capability 1 — Financial Truth

## Responsibility

Represent financial facts exactly as they occurred.

## Owns

- Financial records
- Journal entries
- Immutable financial history

## Does Not Own

- Reports
- Analytics
- Recommendations
- Forecasts

## Consumers

- Balance
- Net Worth
- Analytics
- Projection
- AI
- Reports

---

# Capability 2 — Derived State

## Responsibility

Compute deterministic views from Financial Truth.

## Examples

- Account Balance
- Net Worth
- Cash Flow
- Savings
- Spending totals

## Characteristics

Derived State is always reproducible.

It contains no opinion.

It introduces no new facts.

---

# Capability 3 — Historical Analysis

## Responsibility

Analyze past financial behavior.

## Examples

- Spending trends
- Monthly comparisons
- Category distribution
- Saving history
- Investment performance

Historical Analysis explains what happened.

It never predicts what will happen.

---

# Capability 4 — Projection

## Responsibility

Estimate possible future financial states.

## Examples

- Future balance
- Goal completion date
- Cash flow forecast
- Budget projection

Projection is probabilistic.

Projection never changes Financial Truth.

---

# Capability 5 — Interpretation

## Responsibility

Transform financial information into understandable insights.

## Examples

- Spending explanations
- Financial summaries
- Pattern detection
- Budget observations
- AI-generated narratives

Interpretation explains.

It never authoritatively decides.

---

# Capability 6 — Recommendation

## Responsibility

Suggest possible actions that may improve financial outcomes.

## Examples

- Reduce dining expenses
- Increase savings
- Delay discretionary purchases
- Improve emergency fund

Recommendations are optional.

The user remains the decision maker.

---

# Capability 7 — External Knowledge

## Responsibility

Provide external information required for financial reasoning.

## Examples

- Exchange rates
- Gold prices
- Inflation
- Interest rates
- Market data

External Knowledge enriches reasoning.

It never becomes Financial Truth.

---

# Capability 8 — Explainability

## Responsibility

Explain how conclusions were produced.

## Examples

- Why a recommendation appeared
- How a projection was calculated
- Which transactions affected a result
- Which assumptions were used

Explainability increases trust.

It does not generate financial knowledge.

---

# Capability Relationships

Financial Truth
        │
        ▼
Derived State
        │
        ├─────────────┐
        ▼             ▼
Historical      Projection
Analysis            │
        └──────┬─────┘
               ▼
        Interpretation
               │
        ┌──────┴────────┐
        ▼               ▼
Recommendation   Explainability

External Knowledge
        │
        ├──────────────► Projection
        ├──────────────► Interpretation
        └──────────────► Recommendation

---

# Capability Evolution

Capabilities evolve only when architectural evidence exists.

New capabilities are introduced only when:

- an existing capability cannot naturally express the responsibility
- architectural invariants are threatened
- a genuinely new domain responsibility emerges

Feature growth alone is insufficient.

---

# What Is Not a Capability?

The following are intentionally **not** capabilities:

- Expenses
- Income
- Transfers
- Accounts
- Goals
- Budgets
- Investments
- Notifications
- AI Chat
- OCR
- SMS Import
- Reports

These are features, domain concepts, or consumers of capabilities.

They are implemented using one or more capabilities.

---

# Relationship to Other Documents

Architecture Evolution Principles

Defines how architecture evolves.

Financial Invariants

Defines what must never be violated.

Capability Model

Defines the stable responsibilities of the system.

ADRs

Describe architectural decisions that realize these capabilities.

---

# Summary

Capabilities are the architectural backbone of Wafferly.

They provide stable responsibilities that outlive individual features.

Architecture grows by strengthening capabilities—not by accumulating features.
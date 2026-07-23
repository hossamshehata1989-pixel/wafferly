# Architecture Evolution Principles

**Status:** Active  
**Version:** 1.0  
**Last Updated:** 2026-07-22

---

# Purpose

This document defines how the Wafferly architecture is allowed to evolve over time.

Unlike ADRs, which capture individual architectural decisions, this document defines the principles governing future architectural decisions.

Every new abstraction, capability, subsystem, or architectural proposal MUST be evaluated against these principles before becoming part of the architecture.

---

# Philosophy

Wafferly is designed to survive long-term evolution.

The architecture is intentionally conservative.

New abstractions are not introduced because they appear elegant, reusable, or potentially useful.

They are introduced only when architectural evidence demonstrates that the current model can no longer express the domain correctly.

Architecture follows evidence.

It never follows speculation.

---

# Principle 1 — Financial Truth Comes First

Financial Truth is the foundation of the entire system.

Every architectural decision must preserve the integrity of Financial Truth.

Nothing may optimize, simplify, or generalize the architecture at the expense of Financial Truth.

When a conflict exists between architectural elegance and Financial Truth, Financial Truth always wins.

---

# Principle 2 — Stable Capabilities Over Growing Features

Features evolve continuously.

Capabilities evolve rarely.

Features are consumers.

Capabilities are providers.

New features should reuse existing capabilities whenever possible.

The existence of a new feature does not automatically justify introducing a new capability.

---

# Principle 3 — Architecture Evolves From Structural Evidence

Architecture does not evolve from assumptions.

Architecture does not evolve from possible future requirements.

Architecture evolves only when structural evidence demonstrates that the current architecture no longer models the domain correctly.

Evidence is architectural.

Not speculative.

---

# Principle 4 — Evidence Before Abstraction

Every abstraction introduces permanent complexity.

Therefore:

No abstraction should exist without evidence.

Examples of insufficient evidence:

- "We may need this later."
- "Another application might reuse it."
- "The architecture looks cleaner."
- "Future AI features could benefit."

These are hypotheses.

Not evidence.

---

# Principle 5 — Capability Evolution Rule

A new capability MUST NOT be introduced merely because a new feature exists.

A capability MAY be introduced when one or more of the following conditions become true:

- Existing architectural invariants can no longer be preserved.
- Existing capabilities cannot naturally express the domain.
- A new ubiquitous language emerges that does not belong to any existing capability.
- Multiple independent features require the same structural responsibility.

Until then:

Prefer composition.

Prefer reuse.

Accept temporary duplication over premature abstraction.

---

# Principle 6 — Preserve Existing Invariants

Architectural evolution must preserve established invariants.

If an abstraction weakens an invariant, the abstraction is considered incorrect until proven otherwise.

The burden of proof belongs to the new abstraction.

Never to the existing architecture.

---

# Principle 7 — Prefer Composition Over Expansion

When solving new problems:

Prefer composing existing capabilities.

Avoid expanding existing capabilities beyond their natural responsibility.

Capabilities should become deeper.

Not broader.

---

# Principle 8 — Ubiquitous Language Is a Structural Signal

When a feature introduces vocabulary that does not naturally fit any existing capability, the architecture should pause.

New terminology often indicates either:

- a missing capability
- a missing bounded context
- or a new financial primitive

Vocabulary is evidence.

Not implementation detail.

---

# Principle 9 — Product Discovery Precedes Architecture

Questions reveal needs.

Capabilities satisfy needs.

Architecture organizes capabilities.

Therefore:

Questions are an excellent product discovery technique.

Questions are NOT architectural primitives.

The architecture is organized around stable capabilities.

Not around user questions.

---

# Principle 10 — Architecture Should Remain Explainable

Every major architectural decision should answer:

Why does this abstraction exist?

What evidence justified it?

Which existing principle required it?

If these questions cannot be answered clearly,

the abstraction should probably not exist.

---

# Decision Checklist

Before introducing a new capability, answer:

- What structural evidence exists?
- Which principle requires this capability?
- Which invariant would otherwise break?
- Can an existing capability express this naturally?
- Is this solving today's problem or tomorrow's speculation?

If these questions cannot be answered convincingly,

do not introduce the capability.

---

# Anti-Patterns

The following are considered architectural anti-patterns within Wafferly:

- Speculative abstractions
- Feature-driven architecture
- UI-driven architecture
- Screen-first modeling
- Premature generalization
- Capability proliferation
- Weakening invariants for convenience

---

# Relationship to ADRs

This document does not replace ADRs.

Instead:

Architecture Evolution Principles define *how* architectural decisions are made.

ADRs define *which* architectural decisions were made.

Every future ADR is expected to comply with this document.

---

# Summary

The architecture of Wafferly evolves through evidence.

Not prediction.

Not elegance.

Not speculation.

Architecture is allowed to grow only when reality demonstrates that it must.
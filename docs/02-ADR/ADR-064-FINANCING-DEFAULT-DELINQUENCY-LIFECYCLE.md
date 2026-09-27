# ADR-064 — Financing Default & Delinquency Lifecycle Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052, ADR-055, ADR-057, ADR-060, ADR-061

## Context
Due, overdue, delinquent, and defaulted are different contractual states. Late fees alone do not define the complete lifecycle.

## Decision
Define an explicit lifecycle:
```text
CURRENT
  ↓
DUE
  ↓
OVERDUE
  ↓
DELINQUENT
  ↓
DEFAULTED
```

Exact thresholds are policy/configuration, not implicit code behavior.

## Due
An installment is due according to its contractual due date.

## Overdue
An installment is overdue when:
```text
evaluationDate > dueDate
```
and the eligible obligation remains unresolved.

## Delinquent
Delinquency is reached after an explicit threshold. It must not be inferred from one overdue installment unless policy says so.

## Default
Default is a higher-level contractual state requiring explicit conditions such as days-past-due or number of overdue installments.

## Late Fees
ADR-057 governs late-fee assessment. Default does not automatically create extra fees unless another policy authorizes them.

## Recovery
A delinquent/defaulted contract returns to a non-default state only through an explicit policy event.

## Required Tests
- due → overdue;
- overdue → delinquent;
- delinquency threshold;
- default threshold;
- payment reducing delinquency;
- full settlement;
- late-fee interaction;
- cancellation/termination;
- replacement;
- deterministic evaluation using explicit evaluation date.

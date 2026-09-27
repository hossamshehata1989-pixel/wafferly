# ADR-068 — Financing Audit & Traceability Boundary

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-041, ADR-042, ADR-059, ADR-060, ADR-063, ADR-065, ADR-066, ADR-067

## Context
Financing operations create a chain across contractual state and financial truth. The chain must be preserved without turning audit data into a second financial source of truth.

## Decision
Every material financing transition must be traceable.

```text
Contract
  ↓
Schedule
  ↓
Installment
  ↓
Financing Event
  ↓
Financial Operation
  ↓
Transaction
  ↓
Ledger
```

## Traceability
Where applicable, events retain references to:
- contract ID;
- predecessor/replacement contract ID;
- schedule ID;
- installment ID;
- financing event ID;
- financial operation ID;
- transaction ID;
- actor;
- effective date;
- reason.

## Immutable History
Audit/history is append-oriented. It does not rewrite financial truth.

## Idempotency
An idempotent retry does not create a second financial trace representing a second execution; it references the existing operation/outcome.

## Effective Truth
ADR-042 remains authoritative for effective transaction history. Audit data cannot override financial truth.

## Required Tests
- charge traceability;
- payment traceability;
- settlement traceability;
- replacement chain;
- reversal chain;
- waiver chain;
- retry trace behavior;
- historical immutability;
- no audit-only financial mutation.

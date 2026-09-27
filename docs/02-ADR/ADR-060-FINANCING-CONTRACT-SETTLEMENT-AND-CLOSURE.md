# ADR-060 — Financing Contract Settlement & Closure Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052, ADR-053, ADR-054, ADR-055, ADR-056, ADR-057, ADR-058, ADR-059

## Context
A financing contract needs a deterministic terminal lifecycle. The architecture must distinguish Payment, Settlement, Completion, and Closure. A contract must not be considered closed merely because a UI balance appears to be zero.

## Decision
Introduce an explicit **Financing Contract Settlement & Closure** policy.

```text
Active
  ↓
All Applicable Obligations Resolved
  ↓
Settled
  ↓
Closed
```

Settlement is a domain state transition. Any actual money movement remains a Financial Operation.

## Settlement Conditions
Settlement evaluates:
- remaining principal;
- accrued/applicable interest;
- outstanding fees;
- applicable late fees;
- valid payment allocations;
- outstanding contractual obligations.

No UI-derived balance is authoritative.

## Rounding Residuals
Small residuals caused solely by deterministic monetary rounding may be resolved according to the financing rounding policy. A residual must not be silently discarded.

```text
Rounding Residual ≠ Unpaid Obligation
```

## Future Obligations
After settlement, future unpaid schedule items are explicitly resolved/superseded. No new installment, interest, late fee, statement, or scheduled payment obligation is generated.

## Historical Preservation
Historical transactions, payments, allocations, statements, fees, interest, and schedule occurrences remain immutable.

## Payment vs Settlement
```text
Payment
  ↓
Financial Operation
  ↓
Updated Effective State
  ↓
Settlement Evaluation
  ↓
Contract Settled
```

## Early Settlement
ADR-056 governs early settlement. Full early settlement may result in Settled → Closed, using the explicit early-settlement calculation.

## Idempotency
Repeated settlement must not create duplicate payments, transactions, fees, schedule transitions, or reopen a settled contract.

## Required Tests
- exact final payment;
- rounding residual;
- unpaid fee blocks settlement;
- unpaid late fee blocks settlement;
- future obligations superseded;
- historical records unchanged;
- repeated settlement idempotent;
- settled contract cannot generate new obligations;
- no direct financial mutation by settlement evaluator.

## Invariants
```text
Settled Contract ≠ Deleted Contract
Closure ≠ Historical Mutation
Payment ≠ Settlement State
```

Actual money movement continues through the Financial Operation Engine.

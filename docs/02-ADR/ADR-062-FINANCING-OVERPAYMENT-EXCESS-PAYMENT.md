# ADR-062 — Financing Overpayment & Excess Payment Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-051, ADR-054, ADR-055, ADR-056, ADR-060, ADR-061

## Context
A financing payment may exceed the amount currently allocatable to eligible obligations.

```text
Outstanding = 8,000
Payment     = 10,000
Excess      = 2,000
```

The excess must never be silently absorbed or discarded.

## Decision

The MVP uses a **strict overpayment rejection policy**.

The payment operation must reject a payment when the requested amount exceeds
the amount that can be allocated to eligible financing obligations at the
operation's explicit allocation/evaluation date.

```text
Requested Payment > Eligible Allocatable Amount
        ↓
REJECT
        ↓
No financial mutation
No contract transition
No implicit credit balance
No implicit refund
```

The allocation calculators may still return an explicit `unallocatedAmount` as
a calculation result. A financial payment operation must not commit a result
with a non-zero `unallocatedAmount` under this ADR.

This deliberately defers `REFUNDABLE`, `CREDIT_BALANCE`, and `TRANSFERRED`
behaviors until a separate policy defines their ownership, lifecycle, and
financial effects. `UNALLOCATED` is therefore a calculation result, not a
persisted shadow balance.

## Allocation
ADR-055 and ADR-054 govern eligible allocation:
```text
Installment seniority
  ↓
Fees
  ↓
Interest
  ↓
Principal
```

Remaining amount becomes `unallocatedAmount`.

## Excess Classification

No excess classification is selected for the MVP because an overpayment is
rejected before financial mutation.

Future policies may explicitly introduce `REFUNDABLE`, `CREDIT_BALANCE`, or
`TRANSFERRED` behavior, but such behavior requires a separate ADR and must not
be inferred by this one.

## No Hidden Principal Reduction
Excess must not silently reduce future principal unless an explicit allocation policy authorizes it.

## Refund
If refundable:
```text
Payment
  ↓
Allocated Portion + Refundable Excess
```
Refund is a separate financial effect through the Financial Operation Engine.

## Credit Balance
If excess becomes credit balance, ownership and later application must be explicitly defined. It must not become a shadow financing balance.

## Contract Closure
Excess payment does not by itself imply settlement. ADR-060 remains authoritative.

## Required Tests
- exact payment succeeds;
- partial payment succeeds;
- excess payment is rejected before financial mutation;
- rejected excess leaves Account/Transaction/Ledger/contract state unchanged;
- no silent future-principal reduction;
- refund/credit-balance paths are not implicitly invoked;
- repeated valid payment is idempotent;
- settlement is evaluated only from valid allocated payments.

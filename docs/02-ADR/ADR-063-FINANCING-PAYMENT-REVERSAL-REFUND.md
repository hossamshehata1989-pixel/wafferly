# ADR-063 — Financing Payment Reversal & Refund Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-041, ADR-042, ADR-051, ADR-054, ADR-055, ADR-060, ADR-062

## Context
A previously received financing payment may require reversal or refund. Historical financial truth must remain immutable.

## Decision
This ADR is scoped only to the **reversal/refund of a financing payment**.

It does not define a purchase/charge refund. Credit Card purchase refunds are a
separate Credit Card Charge domain concern and must not be conflated with a
financing-payment refund.

A payment reversal is an explicit compensating financial effect. The original
payment record is never rewritten or deleted.

```text
Original Payment
  ↓
Reversal / Refund Operation
  ↓
Compensating Financial Transaction
```

## Reversal vs Refund
**Reversal** corrects/reverses the financial effect of an existing payment.

**Refund** returns money to the payer.

They may share infrastructure but remain distinct domain intents.

## Allocation Impact
If the original payment had allocations, the reversal creates a compensating
effective allocation outcome through the applicable planning/financial
workflow.

Historical allocation records are immutable. They are never edited to make the
original payment appear as if it never happened.

The effective state therefore derives from:

```text
Original Allocation
        +
Compensating Reversal Allocation Event
        ↓
Current Effective Allocation State
```

## Recalculation
```text
Effective Financial Truth
  ↓
Recalculate Outstanding Obligations
  ↓
Re-evaluate Settlement
```

No direct mutation of historical transactions.

## Idempotency
A stable reversal identity prevents multiple compensating transactions for the same reversal.

## Atomicity
If reversal affects financial truth and contract state, failure/retry must be recoverable without duplicate financial effects.

## Required Tests
- reverse an allocated financing payment;
- reverse a partially allocated financing payment;
- refund a financing payment;
- purchase/charge refund is outside this ADR;
- historical transaction unchanged;
- allocation state restored correctly;
- settlement re-evaluated;
- duplicate reversal prevented;
- atomic failure recovery.

# ADR-047 → ADR-070 Reference Graph Audit

**Date:** 2026-09-27  
**Status:** Verified for the canonical ADR source set used by the financing implementation.

## Canonical numbering

- ADR-047 — Credit Card Charge Operation
- ADR-049 — Credit Limit Domain Guard
- ADR-050 — Credit Card Statement Lifecycle & Due-Date Generation
- ADR-051 — Credit Card Payment / Settlement Operation
- ADR-052 — Installment / Financing Contract Model
- ADR-053 — Interest Calculation and Installment Allocation Model
- ADR-054 — Payment Allocation Order
- ADR-055 — Multi-Installment Payment Allocation
- ADR-056 — Early Settlement / Prepayment Policy
- ADR-057 — Late Payment Fee Policy
- ADR-058 — Financing Contract Rescheduling / Restructuring Policy
- ADR-059 — Financing Contract Replacement / Refinancing Boundary
- ADR-060 — Financing Contract Settlement & Closure
- ADR-061 — Financing Contract Cancellation / Termination
- ADR-062 — Financing Overpayment & Excess Payment
- ADR-063 — Financing Payment Reversal & Refund
- ADR-064 — Financing Default & Delinquency Lifecycle
- ADR-065 — Financing Waiver & Forgiveness
- ADR-066 — Financing Financial Effects Boundary
- ADR-067 — Financing Operation Idempotency
- ADR-068 — Financing Audit & Traceability Boundary
- ADR-069 — Credit Card Statement ↔ Installment Relationship
- ADR-070 — Credit Card Financing Conversion Boundary

## Corrections applied in this revision

1. Credit Card Charge is canonical ADR-047. The legacy filename/header combination using ADR-048 is not treated as a separate ADR.
2. Credit Limit is canonical ADR-049; its internal header was corrected from ADR-048 to ADR-049.
3. ADR-050 now references ADR-047 for Credit Card Charge.
4. ADR-066 now references ADR-047 rather than the stale ADR-048.
5. ADR-067 now references ADR-047 rather than the stale ADR-048.
6. ADR-069 explicitly references ADR-070 as the conversion boundary that establishes the financing/statement relationship.
7. ADR-070 remains the conversion boundary and references ADR-069 for statement eligibility/no-double-counting.

## Critical dependency edges

```text
ADR-047 → ADR-049
ADR-047 → ADR-050
ADR-047 → ADR-051
ADR-047 → ADR-066
ADR-047 → ADR-067

ADR-050 → ADR-069
ADR-052 → ADR-053
ADR-052 → ADR-069
ADR-053 → ADR-069
ADR-051 → ADR-069

ADR-069 ↔ ADR-070
ADR-070 → ADR-047
ADR-070 → ADR-049
ADR-070 → ADR-050
ADR-070 → ADR-051
ADR-070 → ADR-052
ADR-070 → ADR-053
ADR-070 → ADR-059
ADR-070 → ADR-066
ADR-070 → ADR-067
ADR-070 → ADR-068
ADR-070 → ADR-069
```

## Boundary verification

### Financial truth
ADR-047 remains responsible for the posted charge and authoritative liability mutation. Conversion does not create another principal liability.

### Credit capacity
ADR-049 owns credit-limit/exposure validation. Conversion is not a second credit-limit calculation.

### Statement truth
ADR-050 owns statement lifecycle. ADR-069 owns how scheduled installment obligations contribute to statements.

### Financing truth
ADR-052/053 own contractual terms and expected schedule composition. They do not become a second financial balance.

### Conversion
ADR-070 creates contractual financing state around an already-posted charge. It does not reverse, rewrite, or duplicate the original financial transaction.

### Idempotency / traceability
ADR-067 owns logical financing-operation idempotency while the Financial Engine enforces financial idempotency. ADR-068 preserves traceability without becoming a third source of truth.

## Result

No remaining **known** ADR-048 reference exists in the canonical financing source set after this consistency pass. ADR-048 is not a separate canonical ADR in this architecture.

The ADR graph is now aligned with the implemented Statement ↔ Installment read-model boundary. The remaining statement gate is the end-to-end no-double-counting proof.

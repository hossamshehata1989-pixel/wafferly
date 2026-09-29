# Wafferly — ADR Release Status Matrix

**Date:** 2026-09-28  
**Status:** Accepted for V1 release gating

This matrix prevents a design ADR from being mistaken for a completed runtime feature.

| ADR | Boundary / Decision | V1 runtime status | Evidence / scope |
|---|---|---|---|
| 047 | Credit Card Charge | **Implemented** | Financial Engine charge pipeline + credit-limit guard |
| 049 | Credit Limit Domain Guard | **Implemented** | Charge-domain validation |
| 050 | Statement lifecycle / due-date boundary | **Partial / projection scope** | Current statement projection; persisted close lifecycle deferred |
| 051 | Credit Card Payment / Settlement | **Deferred** | No payment operation in V1 |
| 052 | Financing Contract Model | **Foundation implemented** | Contract/schedule/installment foundation used by conversion |
| 053 | Interest / amortization model | **Foundation implemented** | Calculation foundation; broader payment integration deferred |
| 054 | Payment Allocation Order | **Deferred integration** | Policy/calculator boundary only; no V1 payment operation |
| 055 | Multi-Installment Allocation | **Deferred integration** | No V1 payment operation |
| 056 | Early Settlement / Prepayment | **Deferred** | Phase 2 |
| 057 | Late Payment Fee | **Deferred** | Phase 2 |
| 058 | Rescheduling / Restructuring | **Deferred** | Phase 2 |
| 059 | Replacement / Refinancing | **Deferred** | Phase 2 |
| 060 | Settlement / Closure lifecycle | **Deferred** | Phase 2 |
| 061 | Cancellation / Termination | **Deferred** | Phase 2 |
| 062 | Overpayment / Excess Payment | **Deferred enforcement** | No V1 payment operation to enforce rejection |
| 063 | Payment Reversal / Refund | **Deferred** | Phase 2 |
| 064 | Default / Delinquency | **Deferred** | Phase 2 |
| 065 | Waiver / Forgiveness | **Deferred** | Phase 2 |
| 066 | Financial Effects / Writer Boundary | **Implemented as architectural boundary** | Structural writer tests + Financial Engine rule |
| 067 | Financing Idempotency | **Implemented as architectural boundary** | Durable Financial Engine idempotency + conversion recovery/concurrency tests |
| 068 | Audit / Traceability | **Boundary defined** | V1 conversion preserves traceability references; broader financing audit workflows deferred |
| 069 | Statement ↔ Installment Relationship | **Implemented** | Contribution projection + no-double-counting tests |
| 070 | Posted Charge → Financing Conversion | **Implemented** | Durable conversion event + recovery/idempotency + concurrency protection |

## Verification Snapshot

- Architecture: **22/22 passed**
- Financing idempotency/recovery: **5/5 passed**
- Full regression: **240/240 passed**
- Latest analyze checkpoint: **0 compile errors**

## Release Rule

A deferred ADR must not be described in release notes, UI claims, or implementation checklists as an implemented runtime operation merely because its policy document or pure calculator exists. Any future financial effect must use the existing Financial Operation Engine, writer boundaries, Money rules, and idempotency enforcement.

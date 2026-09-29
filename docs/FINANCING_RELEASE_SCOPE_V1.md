# Wafferly — Current Release Financing Scope V1

**Date:** 2026-09-28  
**Status:** Accepted

## Purpose

This document explicitly separates the financing functionality included in the current release foundation from the later financing roadmap. It prevents the ADR set from being interpreted as a claim that every ADR-051 through ADR-065 operation is already implemented.

## Current Release Scope

The current release financial foundation includes the following implemented financing-related capabilities:

- **ADR-047 — Credit Card Charge Operation**
  - Credit-card charge enters the Financial Engine.
  - Credit-limit/exposure validation is enforced by the credit-card domain guard.
  - Financial mutation remains inside the Financial Engine boundary.

- **ADR-049 — Credit Limit Domain Guard**
  - Owns current exposure / available-credit validation for credit-card charge.

- **ADR-050 — Credit Card Statement Lifecycle / Projection boundary**
  - Current implementation provides the statement projection/contribution boundary used by the present release.
  - A fully persisted statement-close lifecycle remains outside the current release scope.

- **ADR-069 — Credit Card Statement ↔ Installment Relationship**
  - Implemented statement/installment contribution projection and no-double-counting behavior for the current conversion flow.

- **ADR-070 — Credit Card Financing Conversion Boundary**
  - Converts an already-posted credit-card charge into contractual financing state.
  - Does not create a second principal financial liability.
  - Conversion persistence is recoverable and idempotent within its financing boundary.

## Explicitly Deferred Financing Phase 2

The following ADRs are **not claimed as implemented in the current release** and remain financing roadmap scope:

- ADR-051 — Credit Card Payment / Settlement Operation
- ADR-054 — Payment Allocation Order integration into a real payment operation
- ADR-055 — Multi-Installment Payment Allocation integration
- ADR-056 — Early Settlement / Prepayment
- ADR-057 — Late Payment Fee Policy
- ADR-058 — Financing Contract Rescheduling / Restructuring
- ADR-059 — Financing Contract Replacement / Refinancing
- ADR-060 — Full Financing Contract Settlement & Closure evaluation
- ADR-061 — Financing Contract Cancellation / Termination obligation classification
- ADR-062 — Financing Overpayment & Excess Payment enforcement
- ADR-063 — Financing Payment Reversal & Refund
- ADR-064 — Financing Default & Delinquency Lifecycle
- ADR-065 — Financing Waiver & Forgiveness

ADR-052 and ADR-053 are treated as **contract/calculation foundations** used by the current conversion flow; their broader operational lifecycle and financial integration remain subject to the deferred financing roadmap above.

## Boundary Rule

Deferral is intentional and must not be interpreted as permission to bypass the existing Financial Engine boundary.

When a deferred financing feature is implemented, any actual financial effect on Account, Transaction, Ledger, Balance, or Financial Engine idempotency must be introduced through the existing Financial Engine architecture and its established writer/idempotency rules.

## Verification Rule

The current release claims only what is demonstrated by implementation and tests. Passing the current test suite does **not** imply that deferred ADRs are implemented.

Current foundation verification:

- Full `flutter test`: **240/240 passed** after V24 hardening.
- `flutter analyze`: **0 compile errors** at the latest verification checkpoint.
- `test/architecture`: **22/22 passed** after V24 hardening.
- `test/financing/financing_idempotency_recovery_test.dart`: **5/5 passed** after V24 hardening.
- Available UI input screens were manually smoke-tested successfully.

This scope document is the authoritative release-scope clarification for the ADR-047 → ADR-070 financing set unless superseded by a later accepted scope decision.

## Documentation Status Rule

The ADR set contains both implemented V1 boundaries and deferred Phase 2 policy decisions. A checked ADR in a design checklist means the decision/boundary is defined; it does not, by itself, mean a corresponding runtime operation exists. Runtime implementation status is governed by the Current Release Scope section above and by the verification gates.

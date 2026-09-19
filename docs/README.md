# Wafferly Architecture Freeze V1 — Documentation Pack

**Status:** Implementation Gate / Pre-Credit-Card Foundation
**Audit Basis:** Current project snapshot in the latest uploaded ZIP and the accompanying terminal log identifying commit `76428f2` (`Debts screen Ux Done + Credit Card Screen 1st`).

## Purpose

This folder is the working architectural reference for the next implementation phase.
It consolidates the current architecture truth, explicitly records known implementation gaps, and defines the contracts that must be respected before real Credit Card financial logic is connected.

## Documents

1. `01-FINANCIAL_FOUNDATION_FREEZE_V1.md`
   - Current foundation truth
   - Blocking defects
   - Definition of Done before Credit Card execution

2. `02-ARCHITECTURE_RECONCILIATION_V1.md`
   - Reconciles existing V4 documentation with the current code
   - Identifies stale claims that must not be used as implementation evidence

3. `03-ADR-035-CREDIT-CARD-DOMAIN.md`
   - Credit Card domain contract
   - Account/Profile/Transaction ownership
   - Credit exposure and purchase/payment semantics

4. `04-CREDIT-CARD-LIFECYCLE_V1.md`
   - Card lifecycle and accounting behavior
   - Statement, due date, payment, refund, and installment boundaries

5. `05-SCHEDULED_MONEY_CONTRACT_V2.md`
   - Occurrence lifecycle
   - Missed occurrence policy
   - Idempotency and transaction linkage
   - Scheduled execution integrity

6. `06-PRE-CREDIT-CARD-IMPLEMENTATION-CHECKLIST.md`
   - Concrete gate checklist for implementation

## Authority Rule

These documents do not silently supersede an accepted ADR. Where this pack identifies a contradiction, the contradiction is called out explicitly and implementation must follow the latest approved decision after reconciliation.

The pack is intended to become the implementation reference once the foundation gate is closed.

## Decision Clarifications Added in V1.1

- `PaymentInstrument` is retained as a thin generic instrument identity/linkage layer; it is not a balance source of truth. `CreditCardProfile` is the Credit Card-specific profile attached to that instrument.
- `Installment / Financing Contract` is the parent/source of truth for financing terms. A `Commitment` is the schedule-facing future payment expectation derived from the contract, not a competing source of financing truth.
- Scheduling-logic duplication and runtime issues are tracked separately as non-blocking backlog items.

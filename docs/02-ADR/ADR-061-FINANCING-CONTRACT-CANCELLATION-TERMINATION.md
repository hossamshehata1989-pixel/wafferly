# ADR-061 — Financing Contract Cancellation & Termination Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052, ADR-056, ADR-058, ADR-059, ADR-060

## Context
Financing contracts may need to end without normal repayment completion. The architecture must distinguish Cancellation, Termination, Early Settlement, Replacement, and Restructuring.

## Decision
Introduce explicit cancellation/termination semantics.

**Cancellation** applies before the defined cancellation boundary.

**Termination** ends an active contract before normal completion.

Neither operation may erase historical financial truth.

## Contract State
Use explicit terminal states such as:
```text
CANCELLED
TERMINATED
```

Exact enum names belong to implementation.

## Effective Date
Cancellation/termination requires an explicit effective date. No implicit `DateTime.now()` determines historical boundaries.

## Outstanding Obligations
Each remaining obligation must be explicitly classified:
```text
Settled
Waived
Transferred
Remain Payable
Subject to Settlement
```
Nothing is implicitly forgiven.

## Future Schedule
After the effective boundary:
- future schedule items are superseded/cancelled;
- no new future occurrences are generated;
- realized financial events remain intact.

## Financial Effects
Cancellation/termination itself is not automatically a financial transaction.

If refund, settlement, fee, or other money movement is required:
```text
Termination Policy
  ↓
Financial Intent
  ↓
FinancialOperationEngine
```

No direct Account/Transaction/Ledger/Hive financial mutation is allowed.

## Replacement Boundary
If the reason is replacement, ADR-059 governs. Generic termination must not hide a replacement relationship.

## Required Tests
- cancellation before activation;
- termination of active contract;
- historical payment preservation;
- future schedule cancellation;
- explicit treatment of outstanding obligations;
- refund/settlement through Financial Operation Engine;
- idempotent retry;
- no direct financial writes.

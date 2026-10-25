# ADR-079 — Credit Card Installment Effective-Date Semantics

**Status:** Accepted
**Date:** 2026-10-25
**Decision Type:** Credit Card Financing Lifecycle and Statement-Cycle Timing
**Related:** ADR-046 (Monthly / Periodic Due-Date Rollover Policy), ADR-050 (Credit Card Statement Lifecycle and Due-Date Generation), ADR-052 (Installment / Financing Contract Model), ADR-069 (Credit Card Statement ↔ Installment Relationship), ADR-070 (Credit Card Financing Conversion Boundary), ADR-077 (Credit Card Installment Down Payment Policy), ADR-078 (Credit Card Entry Mode Controls)

## 1. Context

Wafferly supports two user journeys that create a financing contract for a Credit Card charge:

1. The user made the purchase as an installment purchase from the outset but records it in Wafferly later, possibly with a historical purchase date.
2. The user first recorded a regular Credit Card purchase and later converts that existing purchase into installments.

These journeys can refer to the same transaction date while having different financing effective dates. Treating the app-entry time as the effective date in both paths can classify a backdated installment purchase as a late conversion. When the purchase date is before a statement close but the user records the purchase after that close, the due projection may retain the full original charge and add the installment schedule, double-counting the same obligation.

The current code already distinguishes `FinancingContract.effectiveDate` from `createdAt` at the model level, but the application service previously supplied `DateTime.now()` for both meanings.

## 2. Decision

The application service must receive an explicit `effectiveDate` for every financing conversion request. It must not infer the event's financial meaning from the time the application record was written.

### 2.1 Installment purchase from the outset

When the same workflow creates a Credit Card charge and its installment plan together, the financing effective date is the immutable originating charge's transaction date:

```text
charge.date
    = financing effectiveDate
```

This rule applies even if the user records the purchase later and selects a historical purchase date. The entry path must not classify it as a later conversion merely because `createdAt` is today.

### 2.2 Conversion of an existing regular purchase

When a user selects an already-existing regular Credit Card charge and later converts it, the effective date is the actual conversion event date:

```text
conversion action date
    = financing effectiveDate
```

The original charge date remains unchanged. A conversion after a statement closes must follow ADR-070's closed-statement boundary; it must not be backdated to make a closed statement appear as though the financing plan already existed.

### 2.3 Creation timestamp

`createdAt` always records when the financing record was actually created or persisted. It is not a substitute for `effectiveDate` and must not be overwritten with a historical purchase date.

## 3. First Installment Due Date

The default first installment date must be derived from the date the financing becomes effective and the Credit Card's configured statement-cycle and due-date rules.

- For an installment purchase created from the outset, the reference date is the original purchase date.
- For a later conversion of an existing regular purchase, the reference date is the actual conversion date.
- If the reference event occurs after the current statement close, the default first installment is attached to the next eligible statement cycle, rather than automatically being placed on the immediately upcoming due date of the already-closed statement.
- Explicit user overrides remain supported where the existing screen offers a first-due-date picker.
- When required card-cycle settings are unavailable, the shared policy uses the documented deterministic next-calendar-month fallback.

All entry points must use the shared `CreditCardFirstDueDatePolicy`; they must not maintain separate month arithmetic or silently default to `DateTime.now()` regardless of event date.

## 4. Financial and Historical Invariants

This ADR does not change the financial writer boundary or the conversion semantics established by ADR-069/070.

- Conversion creates no second principal liability.
- The original charge's amount, date, account, and historical financial effect remain unchanged.
- The financing contract and schedule describe the existing obligation; they are not additional principal transactions.
- A backdated purchase that was an installment purchase from the outset must not remain projected as a regular full-principal obligation alongside its installment schedule when its effective date places it in the same eligible pre-close cycle.
- A genuine later conversion retains its actual effective date and respects the closed-statement rule.
- No historical contract or installment is silently rewritten by this code change. Any repair of already-persisted test data or contracts requires a separate, explicit reconciliation decision.

## 5. Required Regression Tests

The implementation gate must verify:

1. `CreditCardFinancingApplicationService.convertCharge` requires an explicit `effectiveDate`.
2. New installment purchases pass the originating charge date as `effectiveDate` from every supported entry path.
3. Later conversions pass the actual conversion action date as `effectiveDate`.
4. `createdAt` remains the actual persistence time in both journeys.
5. First-due-date defaults derive from the correct event date and the shared card-cycle policy.
6. With statement close day 15, a purchase dated 6 October and recorded on 25 October as an installment purchase from the outset uses 6 October as its effective date; a 1,800 EGP original charge must not be forecast in addition to the installment plan, while an unrelated 500 EGP regular charge remains independently forecast.
7. With a statement close day of 15, a genuine conversion occurring on 25 October defaults to the eligible cycle whose close is 15 November and due date is 15 December, unless the user explicitly overrides the date.
8. Retry/recovery continues to converge on the same origin-derived financing contract, schedule, rule, and installment identities.

## 6. Consequences

The transaction date, financing effective date, and record creation time now have separate semantics. Both the original-purchase installment journey and the later-conversion journey can be recorded after the fact without treating one as the other. The shared date policy is the single owner for default first-installment scheduling, reducing the risk that the same cycle rule drifts between entry screens.

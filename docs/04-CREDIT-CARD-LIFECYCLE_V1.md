# Credit Card Lifecycle V1

**Revision:** V1.1 clarification

**Status:** Proposed for Implementation
**Purpose:** Define the financial lifecycle before UI/backend wiring.

## 1. Lifecycle Map

```text
Card Setup
   ↓
Active Card
   ↓
Purchase / Charge
   ↓
Statement Period
   ↓
Statement Closed
   ↓
Payment Due
   ├── Full Payment
   ├── Partial / Minimum Payment
   └── Overdue
   ↓
Liability Reduced
   ↓
Next Statement Cycle
```

Refunds, reversals, fees, interest, and installment conversions are separate financial events that modify the lifecycle state through explicit operations.

## 2. Card Setup

Creating a Credit Card must create or link to a Liability Account and create its Card Profile.

The setup operation must not create a fake opening transaction merely to store the credit limit.

Credit limit is not money owned by the user and is not an asset balance.

## 3. Purchase / Charge

Example:

```text
Purchase = 1,000 EGP
Available Credit = 10,000 EGP
```

Execution concept:

```text
CreditCardChargeOperation
        ↓
Credit-limit / exposure validation
        ↓
Expense recognition
        ↓
Increase card liability by 1,000
```

No cash account is debited for the initial card purchase.

## 4. Statement Formation

Statement membership is determined from the card's statement-cycle rules and posted transaction dates according to the Credit Card domain contract.

A statement view should answer at least:

- Statement period
- Statement balance
- Minimum payment, if available/defined
- Payment due date
- Transactions included
- Credits/refunds included

The statement view must not become an independent duplicate balance ledger.

## 5. Payment Due

The due date comes from the Credit Card domain's statement policy and/or an explicit issuer statement observation.

Once due, the expected payment may be represented by a Commitment/Schedule layer.

That expected event does not itself change account balance.

Only the executed payment transaction changes the liability.

## 6. Full Payment

```text
Source Bank/Cash/Wallet
        ↓
Liability Payment Operation
        ↓
Card liability decreases
Source asset decreases
```

The payment must be idempotent.

## 7. Partial / Minimum Payment

A partial payment reduces the liability by the actual paid amount.

The remaining liability remains outstanding.

The next statement/payment expectation must derive from the resulting financial state and applicable card rules.

Do not mark the entire scheduled payment as financially completed when only a partial amount was actually settled.

## 8. Overdue

Overdue is a temporal/statement state, not a new balance source of truth.

A card becomes overdue when the relevant payment expectation is past due and the required payment condition remains unmet according to the Credit Card domain rules.

Any late fee or interest charged by the issuer must be represented as an explicit financial event rather than inferred from the fact that a payment is overdue.

## 9. Refund / Reversal

A refund against an existing purchase reduces the card liability/exposure.

Preferred history relationship:

```text
Original Purchase
      ↕
Refund / Reversal
```

This allows audit and statement reconciliation.

A refund is not automatically an income event.

## 10. Installment Conversion

Installment conversion is an explicit financing action.

```text
Existing/eligible purchase
        ↓
Installment conversion
        ↓
Installment / Financing Contract
        ↓
Commitment (future payment expectation)
        ↓
ScheduleRule / ScheduleOccurrence
```

The Financing Contract is the parent and source of truth for the financing terms. The Commitment is the schedule-facing projection generated from that contract; it does not independently own the financing economics.

The contract should define:

- financed amount
- term / number of installments
- installment amount or calculation rule
- interest / fees, if any
- first due date
- payment schedule
- early settlement semantics
- cancellation/refund semantics

The Schedule layer owns dates; the financing contract owns the financial rules.

## 11. State vs Projection

The following are derived/read states, not new financial truth accounts:

- Available Credit
- Utilization Ratio
- Amount Due
- Due Soon
- Overdue
- Statement totals
- Card utilization summaries

The account/transaction history remains the financial source from which these values are computed.

## 12. Idempotency Identity

Every card financial operation must have a stable identity.

For scheduled payments, occurrence identity should participate in the idempotency key.

Example concept:

```text
scheduled-liability-payment:{occurrenceId}
```

The concrete key format may be refined during implementation, but it must remain stable across process restarts and retries.

## 13. Transaction Traceability

Card transactions should be traceable to their origin where applicable:

```text
Transaction
 ├── Credit Card Profile / Liability Account
 ├── Original Purchase (for refund/reversal where applicable)
 └── ScheduleOccurrence (for scheduled payments)
```

The exact field names are implementation details. The linkage requirement is architectural.

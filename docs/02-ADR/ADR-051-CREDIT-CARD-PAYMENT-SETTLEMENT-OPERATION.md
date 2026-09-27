# ADR-051 — Credit Card Payment / Settlement Operation

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-032 (Debt Domain Architecture), ADR-035 (Credit Card Domain), ADR-047 (Credit Card Charge Operation), ADR-049 (Credit Limit Domain Guard), ADR-050 (Statement Lifecycle & Due-Date Generation)

## 1. Context

A Credit Card purchase creates or increases a liability. Paying the Credit Card is a different financial operation: money moves from an Asset Account to the Credit Card Liability Account and reduces the outstanding liability.

A payment must therefore not be represented as a negative Credit Card Charge.

```text
Credit Card Charge
    → Liability increases

Credit Card Payment
    → Asset decreases
    → Liability decreases
```

## 2. Decision

Introduce a dedicated `CreditCardPaymentOperation`.

The operation represents an explicit settlement/payment against a specific Credit Card liability account.

Conceptually:

```text
CreditCardPaymentOperation
    ├── sourceAssetAccountId
    ├── creditCardAccountId
    ├── amount
    ├── occurredAt
    ├── payment metadata
    └── execution context
```

The operation enters the existing Financial Operation Engine and does not directly mutate financial persistence.

## 3. Financial Effect

A successful payment produces:

```text
Source Asset Account
    ↓ amount

Credit Card Liability
    ↓ amount
```

Therefore:

```text
Cash / Asset balance decreases
Credit Card outstanding liability decreases
```

The payment must be represented as an actual financial movement through the existing Financial Engine transaction/journal path.

## 4. Payment Is Not a Charge

The following semantic distinction is mandatory:

```text
Charge  ≠ Payment
Payment ≠ negative Charge
```

A payment must not reuse `CreditCardChargeOperation` with a negative amount.

This preserves domain meaning, validation rules, traceability, reporting, and future statement/payment semantics.

## 5. Domain Validation

The payment operation must validate before financial mutation:

1. source asset account identifier is present;
2. credit card account identifier is present;
3. amount is strictly greater than zero;
4. source account exists and is not archived;
5. source account is an Asset Account;
6. target account exists and is not archived;
7. target account is a Liability Account;
8. target account is explicitly typed as `creditCard`;
9. the Credit Card profile exists and is linked to the target account;
10. the payment does not violate the payment/settlement policy defined by the implementation.

The payment operation must not use the Credit Limit Guard as its primary constraint.

A payment releases liability capacity; it does not consume credit capacity.

## 6. Outstanding Liability Constraint

The current outstanding liability remains derived from authoritative financial truth.

The payment must not create a second liability balance.

For a positive outstanding liability:

```text
Outstanding Liability = current credit exposure
```

A normal payment reduces it:

```text
New Outstanding
    = Current Outstanding - Payment
```

The implementation must explicitly define the behavior when the requested payment exceeds the outstanding amount.

That behavior is a separate implementation policy and must not be inferred from the Credit Limit rule.

The system must never silently create a new unrelated asset balance merely because a payment amount exceeds the current liability.

## 7. Statement Relationship

A payment may settle:

- all or part of the current outstanding liability;
- all or part of a previously closed statement;
- an amount selected by the user.

The statement remains a periodic record.

Payment does not mutate the historical statement into a different statement balance.

Conceptually:

```text
Statement
    = what was due for a closed period

Payment
    = actual money movement settling liability
```

The current liability after payment is derived from financial truth.

## 8. Source Account and Liability Account Ownership

The operation must reference two real Accounts:

```text
sourceAssetAccountId
        │
        ▼
   Asset Account
        │
        │ payment
        ▼
creditCardAccountId
        │
        ▼
Credit Card Liability Account
```

`CreditCardProfile` supplies card-specific configuration.

It does not own the outstanding balance.

## 9. Financial Engine Boundary

The operation must enter the canonical Financial Operation Engine.

It must not directly perform:

```text
Hive.box<Account>().put(...)
Hive.box<Transaction>().put(...)
TransactionApplicationService.addTransaction(...)
```

The operation is interpreted, guarded, planned, integrity-checked, and executed through the existing financial pipeline.

## 10. Idempotency

A payment must use the existing Financial Engine idempotency mechanism.

Repeated execution of the same payment operation must produce one financial effect:

```text
First execution
    → payment committed

Retry
    → existing successful result

Second financial mutation
    → forbidden
```

The operation identity must remain stable across retries.

## 11. Atomicity

If execution fails after planning begins, the financial state must not be partially committed.

The following must remain consistent:

```text
Asset Account
Credit Card Liability
Transaction
Journal / Financial Truth
```

A failure must not produce:

```text
Asset decreased
+
Liability unchanged
```

or:

```text
Liability decreased
+
Asset unchanged
```

The existing Financial Operation Engine atomicity and rollback guarantees apply.

## 12. Credit Limit Interaction

Credit Limit is not a payment constraint.

A payment:

```text
Credit Exposure ↓
Available Credit ↑
```

Therefore:

```text
Charge
    → consumes available credit
    → Credit Limit Guard

Payment
    → releases available credit
    → Payment / Settlement validation
```

The generic cash liquidity guard is also not used to decide whether the Credit Card liability can be settled; the source Asset Account's own financial constraints remain applicable to the outgoing asset movement.

## 13. Traceability

The payment must reuse the existing Financial Operation Traceability boundary.

The resulting trace should identify, where supplied by the initiating boundary:

- operation type;
- operation ID;
- idempotency key;
- actor;
- source;
- produced transaction IDs;
- mutation/journal IDs;
- terminal outcome.

Traceability remains audit/history data and is not a second financial source of truth.

## 14. Non-Goals

This ADR does not define:

- minimum payment calculation;
- interest calculation;
- grace periods;
- installment conversion;
- refund/reversal semantics;
- statement generation;
- statement closing;
- automatic scheduled payment execution;
- payment scheduling policy.

These require separate domain contracts where necessary.

## 15. Required Tests

The first implementation gate must cover:

### Successful payment

```text
Asset = 5,000
Liability = 3,000
Payment = 1,000

→ Asset = 4,000
→ Liability = 2,000
```

### Full payment

```text
Liability = 3,000
Payment = 3,000

→ Liability = 0
```

### Zero / negative payment

```text
amount <= 0
→ rejected
→ no financial mutation
```

### Invalid source account

```text
source is not an Asset Account
→ rejected
```

### Invalid target account

```text
target is not a Credit Card Liability Account
→ rejected
```

### Missing / mismatched profile

```text
profile missing
or
profile.accountId != target account
→ rejected
```

### Overpayment boundary

The implementation must have an explicit test for:

```text
Payment > Outstanding Liability
```

The expected behavior must be determined by the selected settlement policy and must not be silently inherited from the Credit Limit Guard.

### Idempotency

```text
same payment twice
→ one financial mutation
```

### Atomic failure

```text
failure during execution
→ no partial Asset/Liability mutation
```

## 16. Architectural Invariants

The following are mandatory:

```text
CreditCardPaymentOperation
        ≠
CreditCardChargeOperation
```

```text
Payment
        ↓
Asset ↓
Liability ↓
```

```text
CreditCardProfile
        ≠
Outstanding Balance
```

```text
Statement
        ≠
Current Liability
```

And:

```text
Credit Card Payment
        ↓
FinancialOperationEngine
        ↓
Financial Truth
```

The Credit Card feature must never become a second financial writer.

## 17. Consequence

Credit Card payments become explicit liability-settlement operations while preserving the existing architecture:

- Accounts remain financial truth.
- Transactions represent actual money movement.
- CreditCardProfile remains card-specific configuration.
- Credit Limit validation remains charge-specific.
- Statement state remains periodic lifecycle data.
- FinancialOperationEngine remains the canonical financial writer.
- Idempotency and traceability remain shared infrastructure.

This provides a clean foundation for future payment allocation, statement settlement, scheduled payments, and more advanced Credit Card settlement rules without conflating them with Credit Card charges.

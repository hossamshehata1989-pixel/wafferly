# ADR-047 — Credit Card Charge Operation

**Status:** Proposed → Implementation
**Date:** 2026-09-26
**Related:** ADR-035 Credit Card Domain, ADR-046 Monthly Due-Date Rollover Policy, ADR-049 Credit Limit Domain Guard

## 1. Context

Credit Cards are financial liabilities, but a card purchase is not equivalent to a cash expense.

For a normal cash expense:

```text
Asset decreases
    +
Expense / transaction recorded
```

For a Credit Card charge:

```text
Credit Card Liability increases
    +
Purchase transaction recorded
```

No cash asset is consumed at the moment of purchase.

Therefore a Credit Card purchase must not reuse the normal cash-liquidity guard semantics.

The existing architecture already establishes:

```text
Account = financial position / balance source of truth
Transaction = actual money movement
Financial Engine = only financial writer
CreditCardProfile = card-specific rules and metadata
```

## 2. Decision

A dedicated `CreditCardChargeOperation` will be introduced.

It will represent the user's intention to charge a purchase against a specific Credit Card liability account.

### Core operation

Conceptually:

```text
CreditCardChargeOperation
    │
    ├── creditCardAccountId
    ├── amount
    ├── merchant/category metadata
    ├── occurredAt
    ├── transaction metadata
    └── execution context
```

The operation does not directly mutate:

* Account
* Transaction
* Hive
* Balance
* CreditCardProfile

It enters the normal Financial Engine pipeline.

```text
CreditCardChargeOperation
          │
          ▼
FinancialInterpreter
          │
          ▼
Credit Card Charge Intent
          │
          ▼
Domain Guards
          │
          ▼
Credit Exposure Validation
          │
          ▼
Planner
          │
          ▼
Integrity Checker
          │
          ▼
Executor
          │
          ├── Transaction mutation
          └── Journal / financial truth mutation
```

## 3. Liability Account remains the balance source of truth

The Credit Card profile must not contain a second outstanding balance.

The current liability is derived from the financial account.

```text
CreditCardProfile
    ├── creditLimit
    ├── statement configuration
    ├── due-date configuration
    └── card metadata

Liability Account
    └── actual outstanding financial position
```

Therefore:

```text
Outstanding Liability ≠ CreditCardProfile.balance
```

There is no `balance` field in the Credit Card profile.

## 4. Credit Limit

The credit limit is represented using the existing `Money` value object.

Conceptually:

```dart
final Money creditLimit;
```

The limit is card-domain configuration.

It is not itself a financial transaction and does not affect net worth.

## 5. Credit Exposure and Available Credit

The canonical definitions of **Credit Limit**, **Current Credit Exposure**, and
**Available Credit** are owned by **ADR-049 — Credit Limit Domain Guard**.

This ADR consumes those derived values for charge validation and must not
redefine their calculation.

The invariant used here is:

```text
Current Credit Exposure + Charge Amount <= Credit Limit
```

Equivalently:

```text
Charge Amount <= Available Credit
```

`Available Credit` is derived and is never persisted as an independent
financial balance.

## 6. Charge validation

A Credit Card Charge must satisfy:

```text
amount > 0
```

and:

```text
resulting credit exposure <= credit limit
```

A charge that exceeds available credit is rejected before execution.

Example:

```text
Limit       = 10,000
Current Exposure = 7,000
Available Credit = 3,000

Charge      = 2,500
Result      = 9,500 exposure
             → allowed
```

But:

```text
Limit       = 10,000
Current Exposure = 7,000
Available Credit = 3,000

Charge      = 3,001
             → rejected
```

## 7. Exact-limit charge

A charge that consumes exactly the remaining available credit is valid.

Example:

```text
Limit       = 10,000
Current Exposure = 7,000
Available Credit = 3,000
Charge      = 3,000

Result:
Exposure = 10,000
Available = 0
```

No arbitrary safety margin is introduced.

## 8. No cash liquidity guard

This is a critical distinction.

The following must NOT happen:

```text
Credit Card Charge
       ↓
Cash Balance Guard
       ↓
Insufficient Cash
```

The card purchase is funded by the card issuer's liability capacity, not by the user's cash account.

Instead:

```text
Credit Card Charge
       ↓
Credit Exposure Guard
       ↓
Credit Limit
```

The cash account remains unchanged.

## 9. Financial effect

For a purchase:

```text
Credit Card Liability ↑
Cash Asset            unchanged
```

The resulting transaction must identify the Credit Card account as the financial side carrying the liability.

The exact journal representation must preserve double-entry integrity when journal persistence is active.

## 10. Payment is a separate operation

A payment is NOT implemented as a negative Credit Card Charge.

It is a separate liability-settlement operation.

Conceptually:

```text
CreditCardPaymentOperation
```

with:

```text
Source Asset ↓
Credit Card Liability ↓
```

Therefore:

```text
Charge  ≠ Payment
```

and:

```text
Charge reversal ≠ Payment
```

## 11. Refund / reversal

Refunds and reversals are separate semantics from payments.

A refund reverses or reduces the financial effect of a purchase.

It must retain a reference to the original charge where applicable.

It must not be modeled as:

```text
payment
```

because a payment transfers money to the creditor, while a refund represents a reversal of purchase liability.

## 12. Idempotency

Every Credit Card Charge must enter the existing Financial Engine idempotency mechanism.

The operation must therefore carry the normal execution context / idempotency identity.

Repeated execution of the same operation must not create duplicate charges.

Expected behavior:

```text
First execution
    → Charge created

Retry
    → Existing OperationResult returned

Second transaction
    → MUST NOT be created
```

## 13. Account ownership

A Credit Card profile references a real liability account.

Conceptually:

```text
CreditCardProfile
       │
       └── accountId
              │
              ▼
       Liability Account
```

The profile does not replace the account.

The account does not contain all card-specific behavior.

This preserves the architecture:

```text
Account
    = financial truth

Profile
    = domain-specific configuration/rules
```

## 14. Non-goals

ADR-047 does NOT define:

* statement generation
* statement closing
* minimum payment calculation
* interest calculation
* grace periods
* installment conversion
* installment schedules
* card payment operation
* refund operation implementation
* automatic due-date commitment generation

Those will be separate contracts.

## 15. Required tests

The first implementation gate must include:

### Charge success

```text
Charge < available credit
→ succeeds
→ liability increases
→ cash remains unchanged
```

### Exceeds available credit

```text
Charge > available credit
→ rejected
→ no transaction persisted
→ liability unchanged
```

### Exact available credit

```text
Charge == available credit
→ succeeds
→ available credit becomes zero
```

### Negative / zero charge

```text
amount <= 0
→ rejected
```

### Idempotency

```text
same operation twice
→ one financial mutation
→ same successful result on retry
```

### Atomic failure

If execution fails after planning begins:

```text
Transaction
Liability
Journal
```

must not be left partially mutated.

## 16. Architectural invariant

The following invariant is mandatory:

> A Credit Card Charge must pass through the Financial Operation Engine and must never directly mutate financial persistence.

Therefore production code must not contain:

```text
Hive.box<Transaction>().put(...)
Hive.box<Account>().put(...)
TransactionApplicationService.addTransaction(...)
```

from the Credit Card feature itself.

The only permitted entry point is the domain/application operation path.

## 17. Resulting architecture

```text
                 CreditCardProfile
                       │
                       │ accountId
                       ▼
              Liability Account
                       │
                       │ balance truth
                       ▼
              ┌─────────────────┐
              │ Financial Engine│
              └────────┬────────┘
                       │
          CreditCardChargeOperation
                       │
                       ▼
                Credit Exposure
                       │
                ┌──────┴──────┐
                │             │
             Allowed        Rejected
                │
                ▼
              Planner
                │
                ▼
             Executor
                │
                ▼
           Financial Truth
```

## 18. Consequence

Credit Cards become a specialized financial domain without creating a second balance system.

The system gains:

* dedicated credit-limit validation
* liability-based financial truth
* engine-level idempotency
* separation between charge and payment
* future compatibility with statements
* future compatibility with refunds
* future compatibility with installments

while preserving the existing Single Writer architecture.

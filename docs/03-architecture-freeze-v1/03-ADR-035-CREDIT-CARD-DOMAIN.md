# ADR-035 — Credit Card Domain

**Revision:** V1.1 clarification

**Status:** Proposed for Implementation
**Scope:** Credit Cards, Financial Engine, Accounts, Transactions, Scheduled Money
**Depends On:** Financial Engine foundation freeze, ADR-034 Money, ADR-032 Debt Domain, Scheduled Money contract

## 1. Context

The current MVP represents Credit Cards as Liability Accounts. The current `CreditCardsScreen` is a static UX prototype and there is no production Credit Card model/profile or Credit Card financial operation in the uploaded snapshot.

A Credit Card cannot safely be implemented by reusing the current cash-expense path unchanged because a card purchase does not consume an asset account balance. It creates or increases a liability while recognizing an expense.

## 2. Decision

Wafferly will model a Credit Card as:

```text
Credit Card
   │
   ├── PaymentInstrument          ← instrument identity / account linkage layer
   │        │
   │        └── Credit Card Profile ← card-specific terms and configuration
   │
   └── Liability Account          ← financial position / balance truth
```

The `PaymentInstrument` layer is a thin conceptual identity/linkage layer. It is **not** a balance ledger and is not allowed to become a second financial source of truth.

For a normal Credit Card, the instrument links to one authoritative Liability Account. `CreditCardProfile` is the Credit Card-specific profile attached to that instrument. The Liability Account remains the authoritative financial position.

### 2.1 PaymentInstrument Decision

`PaymentInstrument` is retained as the generic abstraction for products where one user-facing instrument may coordinate one or more financial accounts. It exists to prevent product identity from being conflated with account balance truth.

The first Credit Card implementation should keep the relationship simple:

```text
PaymentInstrument
      ↓
CreditCardProfile
      ↓
LiabilityAccount
```

A future hybrid product may legitimately map one instrument to more than one account, for example an Asset Account plus a Liability Account. In that case, the accounts remain independently authoritative and the instrument/profile acts only as the relationship and product-rules layer. It must not mirror or recalculate account balances as stored financial truth.

The implementation may persist the profile and instrument metadata together if that reduces unnecessary storage complexity; the conceptual separation remains part of the architecture contract.

## 3. Credit Card Profile Responsibilities

The profile may contain, as applicable:

- Linked liability account ID
- Card display name
- Last-four identifier or equivalent display identity
- Credit limit (`Money`)
- Currency
- Statement-cycle configuration
- Statement closing-day policy
- Payment-due-date policy
- Minimum-payment policy/configuration
- Issuer/card metadata that is not financial balance truth

The exact persistence schema is an implementation decision and must not duplicate account balance truth.

## 4. Credit Exposure

Credit limit is a card term, not a transaction balance.

Available credit is derived:

```text
Available Credit
    = Credit Limit
      - Current Credit Exposure
```

`Available Credit` must not be persisted as a second authoritative balance unless a future ADR explicitly introduces an external/issuer snapshot model.

For the first implementation, credit exposure must be derived from the card's authoritative financial state and the card-domain rules that define which posted/pending amounts consume the limit.

The implementation must define treatment for:

- Purchases
- Merchant refunds
- Fees/interest
- Payments
- Reversals/adjustments
- Converted installments

## 5. Credit Card Purchase Operation

A card purchase is a dedicated financial operation, for example:

```text
CreditCardChargeOperation
```

It must not be implemented by passing the card liability account into the ordinary cash-expense balance guard.

### Accounting meaning

Conceptually:

```text
Debit  Expense / applicable financial classification
Credit Credit Card Liability
```

The operation must validate card-domain constraints, including sufficient available credit according to the card profile and current exposure.

It should not require cash-account liquidity merely because a transaction is an expense.

## 6. Card Payment

A payment against a Credit Card is a liability settlement:

```text
Debit  Credit Card Liability
Credit Source Asset Account
```

The existing commitment-payment pipeline provides a useful semantic foundation for liability settlement, but the payment metadata must be derived from the selected source account/instrument rather than being hard-coded to `cash` / `EGP`.

## 7. Refund / Reversal

A merchant refund or reversal reduces the card liability exposure.

The domain operation must preserve the distinction between:

- a merchant refund/reversal of an earlier purchase, and
- a new cash income event.

A refund should not be forced through a cash-income operation unless actual cash is received outside the card account.

Where possible, a refund should reference the original purchase so history and statement presentation remain auditable.

## 8. Statements

The statement cycle is a Credit Card domain concern, not a generic ScheduleRule concern.

Schedule infrastructure may provide date recurrence, but statement balance, minimum payment, and issuer-specific rules remain owned by the Credit Card domain.

A statement view should be derived from posted financial activity for the relevant statement period.

If Wafferly later needs to capture an issuer-provided statement snapshot that differs from a locally derived value, that external observation must be modeled explicitly rather than overwriting the account balance or silently duplicating financial truth.

## 9. Installments

Installments are not merely a renamed Commitment.

If a card purchase is converted to an installment plan, the architecture must represent:

```text
Card Purchase
      ↓
Installment Financing Decision
      ↓
Installment / Financing Contract  ← contract / terms source of truth
      ↓
Commitment                     ← schedule-facing future obligation projection
      ↓
ScheduleRule / ScheduleOccurrence
      ↓
Actual Payments → Transactions
```

The **Installment / Financing Contract is the parent/domain contract**. It owns the financing terms and contract lifecycle, such as financed principal, term, interest/fees, down payment, installment calculation rules, settlement rules, and contract status.

A `Commitment` is **not a peer source of truth for those financing terms**. It is the schedule-facing representation of the future payment expectation derived from the contract. Its schedule is then materialized through `ScheduleRule` / `ScheduleOccurrence`.

For V1, one installment contract may generate one recurring commitment series. Future implementations may support multiple commitment series (for example principal and fee components) only through an explicit extension of this contract.

Actual settlement remains a Financial Engine transaction and reduces the authoritative liability balance. The schedule/commitment does not change financial truth by itself.

Interest, fees, discounts, and down payments must be represented explicitly according to their financial meaning, with the contract remaining the source of truth for the financing terms.

## 10. Ownership Rules

| Concern | Owner |
|---|---|
| Instrument identity / account linkage | PaymentInstrument |
| Current amount owed | Liability Account / Transactions |
| Credit limit | Credit Card Profile |
| Card identity/display metadata | Credit Card Profile |
| Purchase accounting | Financial Engine via Card operation |
| Payment accounting | Financial Engine via liability settlement operation |
| Statement cycle rules | Credit Card domain |
| Due-date recurrence infrastructure | Schedule Engine |
| Installment financing terms | Installment / Financing Contract |
| Future payment expectation | Commitment + Schedule, derived from contract |
| Derived available credit | Card-domain projection |

## 11. Required Safety Rules

1. No Card purchase may bypass the Financial Operation Engine.
2. No Card purchase may use the cash-account balance guard as its primary credit-limit rule.
3. No `availableCredit` duplicated balance may become source of truth.
4. No new Card financial amount may use internal `double` when `Money` is available.
5. Card payment must reduce the liability and increase the selected source account through one financial operation.
6. Scheduled card-related events must use stable occurrence identity and idempotency.
7. Installment logic must not be smuggled into the generic Commitment model without an explicit financing contract.
8. PaymentInstrument and CreditCardProfile must never become a second balance source of truth.
9. A Commitment representing an installment series must be derived from the Installment / Financing Contract rather than becoming the owner of financing terms.

## 12. Migration From MVP Liability Account

The existing architecture permits Credit Cards to remain represented by Liability Accounts during MVP.

The new profile should therefore attach to the existing liability account instead of introducing a parallel balance ledger.

The migration target is:

```text
Existing Liability Account
        +
Credit Card Profile
        ↓
Credit Card domain behavior
```

This preserves Account ownership of financial position while adding card-specific rules.

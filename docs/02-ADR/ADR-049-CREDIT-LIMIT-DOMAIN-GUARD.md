# ADR-049 — Credit Limit Domain Guard

**Status:** Accepted  
**Date:** 2026-09-26  
**Related:** ADR-032 (Debt Domain Architecture), ADR-035 (Credit Card Domain), ADR-043/045 (Money Boundaries)  
**Supersedes:** Any implicit assumption that a generic balance/liquidity guard is sufficient for Credit Card purchases

## 1. Context

A Credit Card is represented by a Liability Account plus a `CreditCardProfile`.
The Liability Account remains the source of financial position. The profile owns
card-specific terms such as the credit limit.

A card purchase is not a cash expenditure. Therefore, the ordinary cash
liquidity rule must not decide whether a card purchase is allowed.

The card-domain decision is whether the new exposure remains within the
configured credit limit.

## 2. Decision

`CreditCardChargeDomainGuard` is the authoritative domain guard for the
credit-limit constraint of `CreditCardChargeOperation`.

The guard executes before planning/execution and validates:

1. a non-empty account identifier;
2. a strictly positive charge amount;
3. that the referenced Account exists;
4. that the Account is not archived;
5. that the Account is a Liability Account;
6. that the Account is explicitly typed as `creditCard`;
7. that a `CreditCardProfile` exists for the Account;
8. that the profile is actually linked to the same Account;
9. that resulting credit exposure does not exceed the profile's credit limit.

The guard is read-only. It has no mutation capability and must not create,
update, or delete financial state.

## 3. Credit Exposure Rule

For the current MVP, the authoritative liability balance is read through
`CreditCardBalanceReader`.

Liability balances are represented as signed negative balances. Therefore:

```text
Current Credit Exposure
    = max(0, -Current Liability Balance)
```

The charge is permitted only when:

```text
Current Credit Exposure + Charge Amount <= Credit Limit
```

And:

```text
Available Credit
    = Credit Limit - Current Credit Exposure
```

`Available Credit` is derived. It is not persisted as a second balance source
of truth.

## 4. Cash Liquidity Is Not a Card Constraint

The following are intentionally separate rules:

```text
Cash / Asset transaction
    → BalanceDomainGuard
    → available cash liquidity

Credit Card charge
    → CreditCardChargeDomainGuard
    → available credit capacity
```

A Credit Card charge may therefore succeed when the user's cash/asset balance
is insufficient, provided the card's credit exposure remains within its limit.

The generic cash balance guard must not become the primary credit-limit rule.

## 5. Ownership

| Concern | Owner |
|---|---|
| Current financial position | Liability Account / Transactions / Ledger |
| Credit limit | CreditCardProfile |
| Current exposure | Derived from authoritative liability balance |
| Available credit | Derived card-domain value |
| Credit-limit validation | CreditCardChargeDomainGuard |
| Actual charge mutation | FinancialOperationEngine executor |
| Idempotency | Financial Engine IdempotencyGuard |

Neither the profile nor the domain guard owns a duplicate balance.

## 6. Profile Link Integrity

The guard requires the profile returned for the card account to carry the same
`accountId` as the operation target.

This prevents an accidentally misconfigured profile from authorizing a charge
against a different liability account.

## 7. Failure Semantics

A failed credit-limit/domain validation must occur before financial mutation.
Therefore, a rejected charge must not create a `creditCardCharge` Transaction
or alter the card's authoritative balance.

Representative boundary cases are:

```text
Outstanding = 7,000
Limit       = 10,000

Charge 3,000  → allowed
Charge 3,001  → rejected
```

Exact-limit usage is valid:

```text
Outstanding = 7,000
Limit       = 10,000
Charge      = 3,000
Result      = allowed
```

## 8. Non-Goals

This ADR does not define:

- statement closing dates;
- due-date calculation;
- minimum payment;
- interest/grace-period rules;
- refunds/reversals;
- installment financing terms;
- payment/settlement operations.

Those remain separate Credit Card domain decisions.

## 9. Verification

The Credit Card charge pipeline verifies:

- normal charge success;
- insufficient available credit rejection;
- exact remaining-limit success;
- zero/negative amount rejection;
- idempotent retry;
- missing profile rejection;
- profile/account linkage rejection;
- non-credit-card account rejection.

The implementation continues to use the Financial Operation Engine as the only
financial mutation path.

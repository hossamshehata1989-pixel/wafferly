# ADR-072 — Credit Card Linked Bank Account

**Status:** Accepted  
**Date:** 2026-10-10  
**Scope:** Credit-card creation flow, CreditCardProfile metadata, bank-account eligibility  
**Related:** ADR-035 (Credit Card Domain), ADR-047 (Credit Card Charge Operation), ADR-051 (Credit Card Payment / Settlement Operation), ADR-071 (Credit Card Charge Payment Method Change Boundary)

## 1. Context

The credit-card creation flow previously checked only whether at least one active bank account existed. It did not require the user to select a specific bank account or persist that relationship on the newly created credit-card profile.

A mere existence check is insufficient when Wafferly needs to know which bank account is associated with a credit card.

## 2. Decision

Every newly created credit card must be linked to one explicitly selected, active Wafferly bank account.

The selection must identify an existing `Account` whose type is `bank`, group is `liquidity`, and state is active/non-archived. The account's balance is not a prerequisite, and a debit card is not required.

The selected bank account ID is persisted on `CreditCardProfile.linkedBankAccountId`. This reference is distinct from:

- `CreditCardProfile.accountId`, which identifies the credit-card liability account;
- `CreditCardProfile.linkedDebitCardAccountId`, which represents separate optional debit-card metadata.

The linked bank account is the primary associated account and the preferred/default payment source candidate (priority 1) when a supported credit-card payment-source resolution flow is available. This preference is configuration metadata; it does not itself execute a payment or mutate financial truth. Actual settlement remains subject to the approved Financial Operation Execution Engine and settlement-operation boundaries.

## 3. Currency Compatibility

Until a cross-currency payment path using the approved FX architecture is available, a newly created credit card must use the same currency as its linked bank account. The UI derives the card currency from the selected bank account and does not allow it to diverge from the linked account currency.

## 4. User Flow

```text
Add Credit Card Intro
        │ Continue
        ▼
Select Bank Account
        ├── Active bank accounts exist → user selects one
        └── No active bank accounts → Create Bank Account
                                      │ successful creation
                                      ▼
                              selected new account
        ▼
Add Credit Card Details
        │ Create
        ▼
CreditCardProfile + Liability Account
```

The Intro screen exposes one primary action: `Continue`. If a new bank account is created from the selection step, the flow returns automatically with that account selected. The credit-card form displays the linked account and lets the user change it before saving.

## 5. Persistence and Compatibility

`linkedBankAccountId` uses a new Hive field number and is nullable when reading older profiles. Existing credit-card profiles are not rewritten or assigned an inferred bank account. All newly created profiles must be created through the application service with a valid selected account ID.

The selected bank account must be revalidated by the application service at save time. The UI alone is not the eligibility boundary.

## 6. Financial Safety

- The linked relationship is metadata; it is not a balance, transaction, ledger entry, allocation, or commitment.
- Creating a card must not create an opening financial transaction.
- No balance or debit-card requirement is introduced.
- An archived, non-bank, unknown, or currency-incompatible account cannot be used for new-card creation.
- Existing financial-engine ownership and settlement rules remain unchanged.

## 7. Runtime Status

The Intro → bank-account selection → card form flow and profile link persistence are implemented. Actual payment/settlement is a separate operation governed by ADR-051; it does not execute merely because the linked-account metadata exists. The payment UI prefers this linked account when it remains eligible.

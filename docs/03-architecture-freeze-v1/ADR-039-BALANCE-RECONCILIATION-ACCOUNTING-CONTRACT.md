# ADR-039 — Balance Reconciliation Accounting Contract

**Status:** Accepted  
**Date:** 2026-09-24  
**Related:** ADR-036 — Single Writer Boundary; ADR-037 — Balance Reconciliation; ADR-038 — Financial Correction Write Model

## 1. Decision

`Balance Reconciliation` is a first-class Financial Operation. It never edits `Account` balance directly.

The operation reconciles:

```text
System Derived Balance  →  Observed Balance
```

The difference is posted through a dedicated system equity account:

```text
balance_reconciliation_equity
```

## 2. Eligible accounts

The operation is currently defined for accounts represented by the existing `AccountNature` domain:

- Asset
- Liability

The account nature is part of the reconciliation intent. The operation does not infer accounting nature from the numeric sign of the balance.

## 3. Signed balance contract

`systemBalance` and `observedBalance` are signed according to Wafferly's existing balance representation.

- Asset balance increases with debit and decreases with credit.
- Liability balance is represented with the existing liability sign convention: credit increases the liability and debit decreases it.

Therefore:

```text
Asset:
  observed > system  → Debit Account / Credit Reconciliation Equity
  observed < system  → Debit Reconciliation Equity / Credit Account

Liability:
  observed > system  → Debit Reconciliation Equity / Credit Account
  observed < system  → Debit Account / Credit Reconciliation Equity
```

This keeps the journal balanced and makes the resulting derived balance equal to the observed signed balance.

## 4. Transaction write model

A successful reconciliation creates one immutable `FinancialTransactionRecord` with:

- `type = balance_reconciliation`
- amount = absolute reconciliation difference
- `fromAccountId` = credit side
- `toAccountId` = debit side
- `source = balance_reconciliation`
- reconciliation reason recorded in the transaction note

For this dedicated transaction type, `fromAccountId` / `toAccountId` are accounting-side identifiers rather than a claim that physical cash was transferred.

## 5. Journal contract

Every reconciliation creates exactly one balanced journal entry with two lines:

```text
Debit  = affected account OR reconciliation equity
Credit = reconciliation equity OR affected account
```

The total debit must equal the total credit.

## 6. Ledger projection

The reconciliation transaction is projected into the Ledger with `LedgerPurpose.adjustment`.

The Ledger projection is idempotent by the transaction/projection identifier.

No direct balance write is introduced.

## 7. Difference of zero

A zero difference is not a financial operation and is rejected before planning. No transaction or ledger projection is created.

## 8. Reconciliation reasons

`ReconciliationReason` is owned by `BalanceReconciliationIntent`, not by generic `TransactionMetadata`.

Initial reasons:

- `cashCountDifference`
- `bankStatementReconciliation`
- `previouslyUnrecorded`
- `dataMigrationCorrection`
- `other`

The executed transaction preserves the reason for traceability without expanding the shared metadata contract.

## 9. Correction and invalidation

A reconciliation transaction is financial truth and therefore follows the same immutable lifecycle boundary as other Financial Engine transactions:

- Correction: reverse the original reconciliation effect and create corrected reconciliation truth.
- Invalidation: reverse the original reconciliation effect while preserving the original transaction.

No direct edit/delete is introduced.

## 10. Balance source-of-truth rule

The reconciliation application service must obtain the system-side balance from the **derived financial balance**, not the spendable/available balance after planning reservations.

Accordingly, `BalancePort` exposes both concepts:

- `currentBalance()` — derived financial balance.
- `availableBalance()` — spendability balance used by balance guards.

Reconciliation uses `currentBalance()`.

## 11. Idempotency

The Financial Engine continues to use its current idempotency boundary for execution retries. The reconciliation operation accepts an operation-level idempotency key.

Durable persistence of idempotency remains a separate roadmap item and is not silently folded into this ADR.

## 12. UI boundary

Account Edit does not mutate balance. Existing balance display in edit mode is read-only.

A future `Reconcile Balance` action should collect the observed balance and reason, then invoke the application/domain entry point rather than writing an Account balance.

## 13. Result

Balance Adjustment / Balance Reconciliation is now a real Financial Engine operation with explicit accounting semantics, rather than a direct balance mutation or an unsupported placeholder.

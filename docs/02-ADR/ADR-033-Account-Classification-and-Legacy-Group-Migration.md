# ADR-033 --- Account Classification & Legacy Group Migration

-   **Status:** Accepted
-   **Date:** 2026-09-11
-   **Decision Type:** Domain Classification / Data Migration
-   **Related Domain:** Accounts, Liabilities, Receivables, Investments

## 1. Context

Wafferly historically allowed several account types to remain classified
under the generic `AccountGroup.liquidity` group.

The current domain model requires accounts to be classified according to
their actual financial role so downstream domains can rely on a stable
structural classification.

The migration identified these approved legacy mappings:

  Legacy Account Type   Current Group   Expected Group
  --------------------- --------------- ----------------
  `gold`                `liquidity`     `investments`
  `stocks`              `liquidity`     `investments`
  `certificates`        `liquidity`     `investments`
  `lent`                `liquidity`     `receivable`
  `rosca`               `liquidity`     `receivable`
  `creditCard`          `liquidity`     `liabilities`
  `loan`                `liquidity`     `liabilities`

This is a classification migration only. It must not create or alter
financial movements.

## 2. Decision

`AccountGroup` is the authoritative structural classification of an
account.

Legacy accounts are migrated according to the existing production
classification mapping. The migration follows the same source of truth
used by the application, specifically the `resolveGroup()` mapping,
rather than introducing a separate migration-only taxonomy.

Approved mapping:

``` text
gold         → investments
stocks       → investments
certificates → investments
lent         → receivable
rosca        → receivable
creditCard   → liabilities
loan         → liabilities
```

`rosca` is classified as `receivable` because an expected future receipt
represents a future entitlement/receivable, not an active liability.

## 3. Migration Rules

The migration must:

-   be idempotent;
-   update classification metadata only;
-   preserve existing financial balances;
-   preserve existing transactions;
-   preserve existing ledger records;
-   create no financial movement;
-   create no transaction;
-   create no ledger entry;
-   not execute the Financial Operation Execution Engine;
-   not create commitments or schedule occurrences;
-   not derive or overwrite financial truth from classification alone.

Running the migration more than once must produce the same final
classification state.

## 4. Source of Truth

The production account-classification mapping is the source of truth.

The migration must consume that mapping instead of maintaining a second
independent list of business rules.

If the domain taxonomy changes in the future, the classification
decision must be explicitly reviewed rather than silently changing
historical migration behavior.

## 5. Dry-Run Requirement

A dry-run capability/test is required.

The dry-run identifies legacy accounts whose stored classification
differs from the expected classification and reports:

``` text
account type
current group
expected group
```

The dry-run does not mutate financial state.

A passing dry-run confirms detection of the known legacy classification
cases; it does not by itself imply that production data has been
migrated.

## 6. Domain Consequences

After migration:

-   investment-related accounts are structurally classified as
    `investments`;
-   money lent to others is structurally classified as `receivable`;
-   rotating-savings expected receipts remain `receivable` until an
    actual financial receipt occurs;
-   loans and credit-card debt are structurally classified as
    `liabilities`.

Ownership remains separated:

-   **Accounts** owns the structural account and current financial
    position.
-   **Manage** owns debt-related operational workflows.
-   **Planning / Commitment / Schedule** owns future expectations and
    timing.
-   **Debts** provides debt overview/presentation.
-   Actual financial movements continue through the canonical Financial
    Operation Execution Engine.

## 7. Rejected Alternatives

### Keep all legacy accounts under `liquidity`

Rejected because it prevents the account structure from representing the
actual financial role.

### Maintain a separate migration-only classification table

Rejected because it duplicates domain rules and can diverge from the
production classifier.

### Treat expected `rosca` receipt as a liability

Rejected because the expected receipt represents an
entitlement/receivable before the money is actually received.

### Create transactions while correcting classification

Rejected because classification migration is metadata migration, not a
financial operation.

## 8. Invariants

1.  No financial amount changes solely because of classification
    migration.
2.  No transaction is created solely because of classification
    migration.
3.  No ledger entry is created solely because of classification
    migration.
4.  Re-running the migration does not produce additional changes.
5.  Classification is consistent with the production account-group
    resolver.
6.  Future expectations remain separate from executed financial truth.

## 9. Verification

Verification covers:

-   migration execution tests;
-   migration dry-run tests;
-   idempotency;
-   account-balance integrity;
-   transaction/ledger integrity.

The migration is accepted only when the relevant migration tests pass
without changing production classification rules merely to satisfy stale
legacy expectations.

## 10. Status

**Accepted.**

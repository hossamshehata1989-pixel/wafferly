# Wafferly M3.3 — Drift / SQLite Spike Report

**Date:** 2026-11-02
**Baseline reviewed:** `feature/drift-cutover` / `cab531e`
**Scope:** isolated technical spike only. No Wafferly app source, `pubspec.yaml`, ADR, lockfile, Git index, or working tree was modified.

## 1. Executive result

| Area | Result | Meaning |
|---|---|---|
| SQLite composite foreign keys | PASS | Tested with Book-scoped keys and the `Account.nature` composite reference. |
| Partial unique indexes | PASS | Tested the single-default-Book rule. |
| CHECK constraints | PASS | Tested transaction shape, exactly-one source, canonical occurrence identity, and integer-only Minor Units. |
| Triggers | PASS | Representative INSERT and UPDATE guards ran successfully. |
| Financing write order | PASS | Contract → ScheduleRule → FinancingSchedule → Installments → ConversionEvent succeeded with immediate FKs. |
| SQLite transaction rollback | PASS | Simulated a failure and confirmed all earlier dependent writes were rolled back. |
| Financial effect + Idempotency receipt atomicity | PASS | In one SQLite transaction, a simulated failure removed Transaction, Ledger Entry, receipt and result rows together. |
| Drift `.drift` SQL parser/code generation | **NOT RUN** | Dart/Flutter are not installed in this execution environment. A standalone probe package is included for execution in a Dart environment. |
| Android/iOS native build and runtime | **NOT RUN** | Requires the real Flutter toolchain and platform project. |
| Encryption / Android Keystore | **NOT RUN** | Deliberately outside this SQL/code-generation probe. |

**Conclusion:** SQLite's runtime features needed by the representative M3.3 design are validated against the SQLite engine available to Python here. This does **not** complete the Drift spike because `.drift` parsing, code generation, and the real Flutter native runtime have not yet been executed.

## 2. Executed SQLite runtime tests

The test runner is `run_spike.py`; the representative DDL is `representative_schema.sql`.

- SQLite engine reported by Python: `3.46.1`.
- A fresh SQLite connection reported `PRAGMA foreign_keys = 0` before configuration.
- The runner enables `PRAGMA foreign_keys = ON` before applying the schema and verifies the flag is enabled.
- Result: **33 PASS checks** (8 positive-path checks and 25 expected constraint-rejection checks).

Test coverage includes:

1. One default Book enforced by a partial unique index.
2. `accounts(ledger_account_id, nature)` rejecting a mismatched Account nature through a composite FK.
3. Shared system/Chart accounts usable in more than one Book.
4. A user-linked Ledger Account rejected when posted into another Book.
5. Transaction, Correction reversal, Correction replacement and Invalidation source references.
6. Rejection of a Ledger snapshot whose amount/date does not match the selected source.
7. Rejection of a second terminal Correction/Invalidation for the same source.
8. Exactly-one-source CHECK on Ledger Entries.
9. Transaction type-shape, source nature and cross-Book FK validation.
10. Financing Conversion insertion order with immediate FKs.
11. Rollback of earlier dependent writes when a later write fails.
12. Canonical occurrence IDs using `<ruleId>|YYYY-MM-DD` rather than a timestamp string.
13. Integer-only storage tests for Transaction, Ledger Entry, financing principal and installment components/total.
14. Currency scale integer validation and prevention of in-place scale changes.
15. UPDATE-path checks for account nature, Book scope, source snapshot and Minor Unit exactness.
16. Atomic rollback of Transaction, Ledger Entry, Idempotency receipt and receipt result rows together.

The exact console output is saved in `results.txt`.

## 3. Important DDL amendment discovered: SQLite INTEGER affinity is not enough

SQLite column affinity does not by itself guarantee that a value stored in an `INTEGER`-affinity column is an integer. A fractional input such as `1.25` may be stored as `REAL` if the remaining constraints allow it.

This is a material issue for Wafferly because the approved storage decision is Integer Minor Units, not approximate or fractional SQLite values.

**Required DDL rule:** every persisted monetary `*_minor` column must include a type check as well as its range check:

```sql
amount_minor INTEGER NOT NULL
  CHECK (
    typeof(amount_minor) = 'integer'
    AND amount_minor BETWEEN 0 AND 9000000000000000
  )
```

Apply this consistently to every monetary column, including (not limited to):

- `transactions.amount_minor`
- `ledger_entries.amount_minor`
- `financial_idempotency_balance_changes.amount_minor`
- `credit_card_profiles.credit_limit_minor` and nullable `annual_fee_minor`
- `financing_contracts.principal_minor`
- all `financing_installments.*_minor` component and total columns
- all `statement_installment_contributions.*_minor` columns
- `planning_allocations.amount_minor`
- `budgets.amount_minor`
- `goals.target_amount_minor` and `contribution_amount_minor`
- `goal_activities.amount_minor`
- `commitments.amount_minor`

Nullable money columns need a CHECK that remains valid for NULL (SQLite CHECK passes on NULL/unknown); retain the explicit NULL policy in the column definition.

The same strict integer-type check is appropriate for `currencies.minor_unit_scale` and integer flags/counters where fractional values would be invalid.

This amendment is mandatory before the production DDL is frozen.

## 4. Financing order and rollback

The sample DDL uses immediate foreign keys and proves that the `FinancingConversionEvent` cannot be inserted before its referenced contract/schedule/rule rows exist.

The tested successful write order is:

1. Financing Contract
2. Schedule Rule
3. Financing Schedule
4. Installments
5. Conversion Event / success receipt

All are enclosed in one SQLite transaction. The rollback test confirms that an exception after earlier dependent inserts removes those earlier inserts as well.

This is a runtime SQLite test of the agreed sequence. It is not yet evidence that the app's actual services have been refactored to use this sequence.

## 5. Foreign-key activation requirement

SQLite foreign-key constraints must be enabled per connection. The test runner proves the Python connection starts with the setting off and explicitly enables it.

The included Drift probe sets `PRAGMA foreign_keys = ON` in the `NativeDatabase.memory(setup: ...)` callback, before Drift uses the connection. The production database opener must do the same for every connection/isolate. This should also be asserted by a startup test.

## 6. Drift `.drift` parser and code-generation probe

The folder `drift_probe/` contains:

- `pubspec.yaml` — isolated candidate dependency pins.
- `lib/spike_database.dart` — a minimal database class using `@DriftDatabase(include: {'schema_probe.drift'})`.
- `lib/schema_probe.drift` — representative SQL with tables, a composite FK, CHECK constraints, a partial index, a trigger and named queries.
- `bin/run_probe.dart` — runtime assertions for FK activation, constraint rejection, generated named-query API and transaction rollback.

Run from `drift_probe/`:

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run bin/run_probe.dart
```

The Drift documentation confirms `.drift` files support `CREATE TABLE`, `CREATE VIEW`, `CREATE INDEX`, `CREATE TRIGGER` and named `INSERT` / `SELECT` / `UPDATE` / `DELETE` queries. This is why `.drift` remains the preferred schema authoring format. The probe must still be run to confirm the precise production DDL is accepted by the pinned parser/generator.

### Candidate package pins

| Package | Candidate version | Published minimum Dart SDK |
|---|---:|---:|
| `drift` | `2.35.3` | 3.10 |
| `drift_dev` | `2.35.2` | 3.10 |
| `sqlite3` | `3.8.0` | 3.10 |
| `build_runner` | `2.15.1` | 3.8 |

These pins are selected to remain compatible with the app's declared SDK lower bound (`^3.10.7`). **They are candidate pins only, not a resolved dependency graph:** `dart pub get` has not been run here, and no `pubspec.lock` was generated. Package versions and SDK constraints were checked against pub.dev on 2026-11-02.

The latest `build_runner` release visible on pub.dev requires Dart 3.11; pinning `2.15.1` avoids raising the app's declared minimum SDK just to use the newest generator. The final version choice must be checked by Pub resolution in the project's actual Dart environment.

## 7. What is still unverified

1. Drift's analyzer/code generator accepts the exact representative `.drift` file.
2. All target production triggers compile and are included in generated schema creation/migration paths.
3. The generated schema exports and migration strategy retain the SQL-only constraints/triggers.
4. `PRAGMA foreign_keys = ON` remains enabled on the exact NativeDatabase connections/isolate arrangement selected for Wafferly.
5. Android and iOS release builds with the selected sqlite3 native assets.
6. Encryption engine, KeyStore key wrapping, Backup/Restore and key-loss behavior.
7. Full project tests and financial atomicity tests after the actual Drift UnitOfWork implementation.

## 8. Project integrity

- Reviewed baseline: `feature/drift-cutover`, `cab531e`.
- `pubspec.yaml` declares SDK `^3.10.7` and current lock contains `build_runner 2.4.13`, `build 2.4.1`, `analyzer 6.4.1`.
- The current app manifest does not yet contain Drift/SQLite dependencies.
- No Flutter or Dart executable is installed in this execution environment.
- No application files, project dependency files, ADRs, Git index or Git history were changed.
- No commit or push was performed.

## 9. References

- [Drift `.drift` files documentation](https://drift.simonbinder.eu/sql_api/drift_files/)
- [Drift setup documentation](https://drift.simonbinder.eu/setup/)
- [Drift native database documentation](https://drift.simonbinder.eu/platforms/vm/)
- [SQLite foreign key support](https://www.sqlite.org/foreignkeys.html)
- [Drift package](https://pub.dev/packages/drift)
- [drift_dev package](https://pub.dev/packages/drift_dev)
- [sqlite3 package](https://pub.dev/packages/sqlite3)
- [build_runner package versions](https://pub.dev/packages/build_runner/versions)

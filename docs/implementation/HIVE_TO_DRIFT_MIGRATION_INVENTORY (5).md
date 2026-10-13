# Hive → SQLite + Drift Migration Inventory

**Status:** Inventory baseline — for implementation planning, not an approval to migrate data or enable production writes  
**Prepared:** 2026-10-13  
**Related decision:** `docs/02-ADR/ADR-075-HIVE-TO-SQLITE-DRIFT-MIGRATION.md`  
**Related financial constraints:** `ADR-034-Exact-Money-Representation.md`, `ADR-067-FINANCING-OPERATION-IDEMPOTENCY.md`  

## 1. Purpose and scope

This inventory records the Hive persistence surface found by static inspection of the supplied Wafferly project snapshot. Its purpose is to provide the implementation checklist for designing Drift tables, DAOs, repositories, and the new `UnitOfWork` before replacing Hive in the application path.

The agreed pre-launch strategy is a **clean Drift cutover before external friend testing**. It is not a general migration of production users. Do not add dual-write. A one-time export/import utility for the developer's own test data is optional and must be kept separate from app startup and normal financial execution.

### Snapshot limitations

- The ZIP inspected contains `lib/`, `test/`, and documentation, but it does **not** contain `pubspec.yaml` or native Android project files. Dependency versions, Android build configuration, and SMS permissions therefore cannot be verified from this snapshot.
- The box list below comes from `lib/main.dart` plus direct `Hive.openBox` calls found in `lib/`. Reconcile it against the complete working tree before schema freeze if files absent from the supplied ZIP exist elsewhere.
- This is a source inventory, not proof that all flows or tests currently pass. No Flutter build, `flutter analyze`, or test suite was run as part of this inventory.

## 2. Executive inventory

- **23 boxes are opened in `main.dart`.**
- **1 additional box** (`manual_reserve_names`) is opened lazily by `ManualReserveApplicationService`.
- **24 named Hive boxes in total** were identified in the supplied `lib/` snapshot.
- The app registers **31 Hive adapters** from `main.dart`.
- Four noteworthy adapter findings require review: the custom and generated `Account` adapters share Type ID `1`; `AccountTypeAdapter` (ID `4`), `GoalFundingMethodAdapter` (ID `63`), and `GoalFrequencyAdapter` (ID `64`) are present in generated/source code but are not registered in `main.dart`.
- The current bootstrap contains a `resetDb` debug switch that deletes only a subset of boxes. Do not use this partial reset as the Drift cutover mechanism.

## 3. Hive box inventory

The “key” column describes the stable identifier found in the model or current persistence code where verified. If marked **verify**, confirm all write paths before finalizing the Drift primary key. The priority is migration-design priority, not a statement that data must be imported in the clean cutover.

| # | Hive box | Stored type | Domain / purpose | Key or relationship to preserve | Priority and notes |
|---:|---|---|---|---|---|
| 1 | `accounts` | `Account` | Financial accounts, including asset/liability accounts | `Account.id`; references from transactions, financing contracts, and card profiles | **P0** — financial core. Preserve account classification, currency, `bookId`, `memberId`, archive state, and links. Current registration uses `AccountMigrationAdapter` at Type ID 1. |
| 2 | `transactions` | `Transaction` | Financial transaction records | `Transaction.id`; links `fromAccountId`, `toAccountId`, category, schedule, and commitment | **P0** — financial core and idempotency outcome. Preserve transaction identity; do not create a second financial-truth table for SMS. |
| 3 | `ledger_entries` | `LedgerEntry` | Ledger/journal entries linked to transactions and accounts | `LedgerEntry.id`, `transactionId`, `accountId` | **P0** — preserve relation to the originating transaction and ledger meaning defined by existing ADRs. |
| 4 | `ledger_accounts` | `LedgerAccount` | Ledger account/catalog records, including system accounts | `LedgerAccount.id`, optional `parentId` | **P0** — inspect seeder behavior and retain stable system-account IDs. |
| 5 | `financial_corrections` | `Map` | Before/after snapshots for financial corrections | `correctionId`; references `originalTransactionId` | **P0** — currently an untyped map schema without an explicit `version` field in the inspected writer. Model a typed Drift record and an explicit schema version. |
| 6 | `financial_invalidations` | `Map` | Invalidation records with the original transaction snapshot | `invalidationId`; `originalTransactionId` | **P0** — currently an untyped map schema without an explicit `version` field in the inspected writer. Preserve the original financial snapshot and lookup by original transaction. |
| 7 | `financial_idempotency` | `Map` | Durable successful-operation outcomes | Operation `idempotencyKey`; stores result type and execution summary | **P0** — writer records `version: 1`, `resultType`, created transaction IDs, balance changes, and mutation IDs. Required for safe retries; align with ADR-067. |
| 8 | `financial_traceability` | `Map` | Immutable operation trace/history | `traceId`; indexed lookups by `idempotencyKey` and transaction IDs | **P0** — writer records `version: 1`, status, source, operation IDs, linked transactions/mutations, errors, and timestamps. Define typed columns/relations and indexes. |
| 9 | `credit_card_profiles` | `CreditCardProfile` | Card configuration linked to a liability account | `CreditCardProfile.id`, `accountId`, linked bank/debit account IDs | **P0** — card limits/fees are configuration, not financial truth. Preserve decimal-string money fields and account linkage. |
| 10 | `financing_contracts` | `FinancingContract` | Financing contract terms | `contractId`, `liabilityAccountId`, optional predecessor contract ID | **P0** — contract terms and lifecycle; principal is represented as a canonical decimal string. Do not treat the contract as the authoritative account balance. |
| 11 | `financing_schedules` | `FinancingSchedule` | Financing schedule linked to contract and `ScheduleRule` | `scheduleId`, `contractId`, `scheduleRuleId` | **P0** — preserve contract/schedule references and status. |
| 12 | `financing_installments` | `FinancingInstallment` | Expected repayment obligations | `installmentId`, `contractId`, `scheduleId`, optional `occurrenceId` | **P0** — preserve due date, sequence, status, and decimal-string components (principal, interest, fees, total). An expected installment is not itself a completed payment. |
| 13 | `statement_installment_contributions` | `StatementInstallmentContribution` | Relationship/read-model between statement cycle and installment | `contributionId`; model helper derives identity from statement ID + installment ID | **P1** — preserve statement/contract/installment links. The model marks this as presentation/period state, not financial truth. Confirm unique constraints from actual writers. |
| 14 | `financing_conversion_events` | `FinancingConversionEvent` | Durable workflow record for converting a card charge to financing | `conversionId`, `originChargeId`, contract/schedule/rule IDs | **P0** — not the Financial Engine idempotency store; needed for deterministic conversion recovery. |
| 15 | `planning_allocations` | `HiveAllocationRecord` | Persisted planning-allocation records | Record identity — **verify current repository write key** | **P1** — inspect its repository and projection consumers; keep it distinct from ledger/transaction truth. |
| 16 | `budgets` | `Budget` | User budget definitions | `Budget.id`, `categoryId` | **P1** — preserve period, amount, and creation timestamp; money storage must follow ADR-034. |
| 17 | `goals` | `Goal` | Savings goals and goal settings | `Goal.id`; optional source/saving account IDs | **P1** — preserve status, target/recurrence fields, and account links. Do not assume `GoalFrequencyAdapter` is used; it is not registered in `main.dart`. |
| 18 | `goal_activities` | `GoalActivity` | Goal activity/history | Model identity — **verify current service write key** | **P1** — inspect all writers and define uniqueness and retention requirements. |
| 19 | `members` | `MemberModel` | Book/member attribution and owner record | Model identity — **verify current seeder/controller write key** | **P1** — preserve the owner row and all `actorMemberId`/account member relationships. |
| 20 | `commitments` | `Commitment` | Commitment/scheduled-money domain records | Commitment model identity — **verify current write key** | **P0/P1** — preserve status, amount mode, type, and links used by scheduled financial execution. Final priority depends on scope of enabled scheduled features at cutover. |
| 21 | `schedule_rules` | `ScheduleRule` | Rules defining scheduled occurrences | Schedule rule identity — **verify current model/write key** | **P0** for enabled scheduled execution — preserve recurrence/time-zone/date semantics and references. |
| 22 | `schedule_occurrences` | `ScheduleOccurrence` | Individual scheduled occurrences and their lifecycle | Occurrence identity — **verify current model/write key** | **P0** for enabled scheduled execution — preserve unique occurrence identity/status and links to transactions/commitments. |
| 23 | `scheduled_execution_journal` | `Map` | Execution/recovery journal for scheduled occurrences | Key is `occurrenceId`; stores `idempotencyKey` and state | **P0** for enabled scheduled execution — states include `executing`, `financial_succeeded`, `completed`, `failed`. Inspected writer has no explicit `version` field; typed schema and recovery rules must be specified. |
| 24 | `manual_reserve_names` | `String` | Optional user-entered labels for manual reserves; UI metadata only | Key is `sourceId`; value is trimmed name | **P2** — opened lazily by `ManualReserveApplicationService`; not opened in `main.dart`. Preserve only if the related planning-reservation feature remains in scope. |

### Notes on the inventory

1. The exact count is 23 bootstrap boxes plus one lazily opened box. There may be other key/value APIs in a complete repository not present in the supplied snapshot; rerun the search against the final working tree before implementation.
2. `financial_*` and `scheduled_execution_journal` are currently `Box<Map>` records. Do not blindly translate arbitrary maps into opaque JSON columns. Define typed Drift schemas, explicit versioning, nullability, constraints, and indexes for each supported record.
3. `resetDb` in `main.dart` currently deletes only eight boxes (`accounts`, `transactions`, ledger boxes, budgets/goals/members, and card profiles). It does not delete all 24 boxes. Keep this debug-only and do not reuse it for clean cutover or production recovery.
4. `manual_reserve_names` is opened on demand, so a search limited to boxes opened in `main.dart` would miss it.

## 4. Adapter inventory

The following adapters are registered in `main.dart` in the supplied snapshot. Keep registration details for compatibility review; the clean-cutover plan does not require importing existing Hive data, but it does require understanding each persisted model before designing its Drift equivalent.

| Type ID | Registered adapter | Stored type |
|---:|---|---|
| 1 | `AccountMigrationAdapter` | `Account` |
| 2 | `AccountNatureAdapter` | `AccountNature` |
| 3 | `AccountGroupAdapter` | `AccountGroup` |
| 10 | `TransactionAdapter` | `Transaction` |
| 20 | `EntryTypeAdapter` | `EntryType` |
| 21 | `LedgerPurposeAdapter` | `LedgerPurpose` |
| 22 | `LedgerEntryAdapter` | `LedgerEntry` |
| 30 | `LedgerAccountTypeAdapter` | `LedgerAccountType` |
| 31 | `LedgerAccountAdapter` | `LedgerAccount` |
| 40 | `BudgetPeriodAdapter` | `BudgetPeriod` |
| 41 | `BudgetAdapter` | `Budget` |
| 60 | `GoalAdapter` | `Goal` |
| 61 | `GoalStatusAdapter` | `GoalStatus` |
| 62 | `GoalTypeAdapter` | `GoalType` |
| 70 | `MemberModelAdapter` | `MemberModel` |
| 90 | `GoalActivityAdapter` | `GoalActivity` |
| 91 | `CommitmentTypeAdapter` | `CommitmentType` |
| 92 | `CommitmentStatusAdapter` | `CommitmentStatus` |
| 93 | `CommitmentAmountModeAdapter` | `CommitmentAmountMode` |
| 94 | `FrequencyAdapter` | `Frequency` |
| 95 | `ScheduleRuleAdapter` | `ScheduleRule` |
| 96 | `CommitmentAdapter` | `Commitment` |
| 97 | `HiveAllocationRecordAdapter` | `HiveAllocationRecord` |
| 98 | `ScheduleOccurrenceAdapter` | `ScheduleOccurrence` |
| 99 | `ScheduleOccurrenceStatusAdapter` | `ScheduleOccurrenceStatus` |
| 100 | `CreditCardProfileAdapter` | `CreditCardProfile` |
| 110 | `FinancingContractAdapter` | `FinancingContract` |
| 111 | `FinancingScheduleAdapter` | `FinancingSchedule` |
| 112 | `FinancingInstallmentAdapter` | `FinancingInstallment` |
| 113 | `StatementInstallmentContributionAdapter` | `StatementInstallmentContribution` |
| 114 | `FinancingConversionEventAdapter` | `FinancingConversionEvent` |

### Adapter hazards to resolve

- **Type ID 1 is shared by two adapter implementations in source:** `AccountMigrationAdapter` and generated `AccountAdapter`. `main.dart` registers `AccountMigrationAdapter`, not the generated adapter. The custom adapter performs legacy-value fallbacks for `nature` and `group`. Do not remove or replace it by name alone; document and test its behavior before any cleanup.
- `AccountTypeAdapter` (Type ID 4), `GoalFundingMethodAdapter` (63), and `GoalFrequencyAdapter` (64) exist in generated/source files but are not registered in `main.dart` in this snapshot. Their usage and any historical stored values must be checked before deleting them or their models. A clean-start plan reduces migration duties but does not make unsafe source deletion acceptable.
- Adapter Type IDs are a Hive serialization detail, not Drift table IDs. Do not carry them into the SQL schema as primary keys or infer SQL table relationships from them.

## 5. Storage consumers and boundaries

The main consumer clusters found in `lib/` are:

- **Accounts and transactions:** `AccountService`, `BalanceService`, transaction entry/controller and query/application services, and `HiveTransactionPort`.
- **Financial operation metadata:** Hive correction, invalidation, idempotency, and traceability adapters wired through `financial_engine_bootstrap.dart`.
- **Ledger:** ledger service/account service, account seeder, and ledger-related projections.
- **Card and financing:** `CreditCardProfile` repository, credit-card application/projection services, financing contract/schedule/installment services, and relevant screens.
- **Budgets/goals/members:** budget and goal services, goal activities, member controller/seeder.
- **Scheduled money:** commitments, schedule rules, occurrences, and scheduled execution journal.
- **Planning:** planning allocation persistence and manual-reserve name metadata.

The migration must replace direct Hive reads/writes in these paths, not merely change `main.dart` to open a Drift database. UI code and domain/application services that call `Hive.box(...)` directly must be routed through repositories/ports as part of the cutover.

## 6. Drift schema design requirements

Before coding the final schema, produce a table-by-table mapping from each inventory row to:

- Drift table(s), generated data class, DAO/repository, and owning domain;
- primary key and natural/unique constraints;
- foreign-key or application-level relationship constraints;
- indexes required by current query patterns (especially transaction by account/date, occurrence lookup, idempotency key, traceability by transaction, and correction/invalidation by original transaction);
- creation/update timestamps and status representation;
- seed data and stable system IDs;
- exact schema version and test fixture coverage.

### Exact money

Follow `ADR-034-Exact-Money-Representation.md`: `Money` backed by `Decimal` is the authoritative domain representation; `double` may remain only at legacy/persistence boundaries with explicit conversions. The existing `Transaction`, `LedgerEntry`, `Budget`, and `Goal` models contain `double` fields, while card limits and several financing amounts use canonical decimal strings. Do not blindly perpetuate this inconsistency into domain arithmetic. Decide each Drift persistence representation explicitly and test round-trips without silently rounding or changing financial meaning.

### Financial truth versus projections/configuration

- Accounts and transactions retain their existing financial meaning and stable identities.
- Ledger records and financial correction/invalidation records must retain their existing references and lifecycle semantics.
- Card profiles are configuration and link to real account records; they must not become a second source of card balance.
- Financing contracts and installments describe terms/expected obligations; they do not replace actual executed transactions as financial truth.
- Statement installment contributions are described by the model as presentation/period state, not financial truth.
- Idempotency and traceability records are operational integrity records, not transactions themselves.
- Planning allocations and manual-reserve labels must not be promoted to account balance or ledger truth.

## 7. Clean-cutover execution checklist

This checklist is for the pre-launch, no-external-users scenario agreed in ADR-075.

### A. Before code cutover

- [ ] Re-run this inventory against the full local repository (including `pubspec.yaml`, platform files, and any files absent from the shared ZIP).
- [ ] Confirm each box's write key, query patterns, data invariants, seed behavior, and owning repository.
- [ ] Resolve Type ID 1 adapter behavior and investigate unregistered generated adapters.
- [ ] Finalize the Drift schema, indices, constraints, migrations for future SQL schema versions, and exact-money representation.
- [ ] Define typed schemas/versioning for the four `financial_*`/journal Map boxes.
- [ ] Decide whether the developer needs a one-time export/import tool for personal test data. It must not run implicitly at app startup.

### B. Replace the persistence path

- [ ] Add Drift/SQLite dependencies and generated code in the full Flutter project (not in this inventory-only step).
- [ ] Implement one Drift database instance and DAOs/repositories for the required domains.
- [ ] Replace direct `Hive.box(...)` usage in app paths with repository/port dependencies.
- [ ] Implement a real Drift-backed `UnitOfWork` using one database transaction for all changes that constitute a single financial effect.
- [ ] Keep exactly one active store for financial writes. **No dual-write and no silent fallback to Hive after Drift accepts writes.**
- [ ] Replace or remove Hive bootstrap/adapter registration only after all consumers have moved and tests prove that Hive is not read on the production path.
- [ ] Do not use the partial `resetDb` block in `main.dart` as the cutover strategy.

### C. Required verification before enabling financial writes in production

- [ ] Every inserted/updated/deleted transaction and its dependent ledger/correction/invalidation/idempotency/traceability records obey the intended atomicity boundary.
- [ ] Retrying the same logical operation reuses the same stable `idempotencyKey` and does not duplicate a transaction, ledger movement, contract transition, or scheduled execution.
- [ ] Tests cover interruption before commit, after commit but before the caller sees success, and retry after process/database reopen.
- [ ] Test concurrent confirmation/retry of the same operation.
- [ ] Test linked account, transaction, card profile, contract, schedule, and installment references.
- [ ] Test exact-money round trips and current financial invariants from ADR-034.
- [ ] Test completely offline operation with no cloud requirement.
- [ ] If a one-time personal-data import is used, compare record counts, stable IDs, account links, scheduled items, financing relationships, and recomputed balances before deleting the old test data.
- [ ] Run `flutter pub get`, code generation, `flutter analyze`, and all relevant tests from the full project before declaring cutover complete.

## 8. Explicit non-goals

- No production-user data migration is planned for the pre-launch clean cutover.
- No dual-write period is planned.
- No automatic import of old Hive test data is planned; a personal one-time tool is optional.
- This inventory does not design SMS tables in detail; SMS-specific fingerprint and draft tables remain governed by ADR-074 and should be designed after the base Drift schema and transaction boundary are clear.
- This inventory does not claim the Drift migration, financial `UnitOfWork`, or any test gate has been implemented.

## 9. Definition of done for this inventory

This inventory is ready to guide implementation when the full repository has been checked against it, the “verify” key cells have explicit decisions, all box consumers are mapped to repositories/DAOs, and the Drift schema design records satisfy the constraints in Section 6. It is not itself the implementation sign-off.

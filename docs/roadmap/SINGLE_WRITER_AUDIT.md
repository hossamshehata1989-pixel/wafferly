# Single Writer Audit

**Roadmap position:** Phase 2 — Writer Audit. This audit preserves the
existing Post Engine Integration Roadmap terminology; it does not rename or
advance any gate.

**Authority:** ADR-004 / `Wafferly_Project_Rules.md` Rule 14, Rule 22,
Rule 69. Financial reality is created by `FinancialOperationEngine`.
Repositories and ports persist planned mutations only.

| Path | Component | What it writes | Current caller | Canonical replacement | Status | Risk |
| --- | --- | --- | --- | --- | --- | --- |
| `lib/services/transaction_application_service.dart:addExpense` | TransactionApplicationService | Expense transaction, ledger projection | TransactionEntryController | Existing ExpenseOperation | A | Low |
| `lib/services/transaction_application_service.dart:addIncome` | TransactionApplicationService | Income transaction, ledger projection | TransactionEntryController | Existing IncomeOperation | A | Low |
| `lib/services/transaction_application_service.dart:addTransfer` | TransactionApplicationService | Transfer transaction, journal/ledger | TransactionEntryController | Existing TransferOperation | A | Low |
| `lib/services/transaction_application_service.dart:updateExpense/updateIncome/updateTransfer` | TransactionApplicationService | Corrected transaction and rebuilt ledger | TransactionEntryController | Existing CorrectionOperation | A | Low |
| `lib/services/transaction_application_service.dart:delete` | TransactionApplicationService | Transaction deletion and ledger deletion | TransactionsScreen | Existing DeleteOperation | A | Low |
| `lib/application/accounts/account_transaction_service.dart:createInitialBalance` | AccountTransactionService | Opening-balance transaction and journal | CreateAccountUseCase | Existing OpeningBalanceOperation | A | Low |
| `lib/features/financial_action_center/services/financial_action_executor.dart` | FinancialActionExecutor | Executed commitment payment and financial records | Financial Action Center | Existing CommitmentPaymentOperation | A | Low |
| `lib/screens/planning/goal_details_screen.dart:_executeTransfer` | GoalDetailsScreen | Allocation release, goal activity, transfer, journal | Reserved sources transfer dialog | Existing GoalTransferOperation | A (migrated in this audit) | Low; equivalent plan covers all four mutations |
| `lib/financial_engine/adapters/hive_transaction_port.dart` | HiveTransactionPort | Transaction save/update/delete | Engine mutation handlers | N/A — TransactionPort adapter | F | Low; must remain persistence-only |
| `lib/infrastructure/ports/hive_ledger_port.dart` | HiveLedgerPort | Ledger entries / transaction-linked deletion | Engine journal mutation handler | N/A — Ledger port adapter | F | Low |
| `lib/infrastructure/adapters/goal_activity_adapter.dart` | GoalActivityAdapter | GoalActivity mutation | Engine goal activity handler | N/A — GoalActivityPort adapter | F | Low |
| `lib/infrastructure/adapters/allocation/create_allocation_adapter.dart` | AllocationAdapter | Planning allocation create/release | Engine allocation mutation handlers | N/A — Planning port adapter | F | Medium; shared planning repository identity is required |
| `lib/core/planning/infrastructure/repositories/hive_allocation_repository.dart` | HiveAllocationRepository | Planning allocation save/update/delete | PlanningEngine and engine allocation adapter | N/A — allocation persistence adapter | F | Medium |
| `lib/services/transaction_application_service.dart:addTransaction` | TransactionApplicationService | Arbitrary transaction plus passive ledger projection | TransactionEntryController legacy fallback | Expense/Income/Transfer operations exist; generic type dispatch does not | B | High; no safe generic equivalent until type-to-command routing is explicit |
| `lib/services/transaction_application_service.dart:updateTransaction` | TransactionApplicationService | Arbitrary transaction update and ledger replacement | No production caller found | CorrectionOperation exists | C | Medium; public compatibility API still bypasses policy/idempotency |
| `lib/services/transaction_application_service.dart:deleteTransaction` | TransactionApplicationService | Transaction and linked ledger deletion | No production caller found | DeleteOperation exists | C | Medium; public compatibility API still bypasses policy/idempotency |
| `lib/services/transaction_application_service.dart:deleteAllTransactions` | TransactionApplicationService | Clears all transactions only | No production caller found | None | B | High; would orphan ledger/history and has no safe engine bulk operation |
| `lib/services/transaction_service.dart:addTransaction/updateTransaction/deleteTransaction/deleteAllTransactions` | TransactionService | Direct transaction CRUD and passive ledger projection | Legacy application methods, TransactionEntryController fallback, GoalDetailsScreen, LedgerStressTestService | Operation-specific engine operations exist except bulk delete and generic routing | B | High; active direct UI writes remain |
| `lib/services/ledger_service.dart:createEntry/createEntries/deleteEntriesByTransactionId/deleteAllEntries` | LedgerService | Direct ledger CRUD | HiveLedgerPort; legacy TransactionService; LedgerSandboxService | Engine journal mutation path for financial records; none for sandbox/bulk cleanup | B/F | High for public legacy CRUD; adapter call is F |
| `lib/services/ledger_account_service.dart:createAccount/deleteAllAccounts` | LedgerAccountService | Ledger chart/account metadata | LedgerAccountSeeder, category mapper, tests | N/A for chart metadata; journal entries remain engine-owned | B | Medium; must not be used to create executed movements |
| `lib/services/ledger_projection_service.dart` | LedgerProjectionService | Derived ledger entries | Engine CreateTransactionMutationHandler; legacy TransactionService | Engine handler path exists | C | Medium; legacy caller produces dual lifecycle semantics |
| `lib/services/account_service.dart:createAccount/createSystemAccount/updateAccount/archiveAccount/clearAllAccounts` | AccountService | Account metadata and archive flag | AccountApplicationService/use cases, account UI, development/test paths | Account creation plus opening balance is already split: metadata persistence then OpeningBalanceOperation | F/C | Medium; account metadata is not movement, but balance-affecting update is blocked by AccountTransactionService |
| `lib/application/accounts/use_cases/update_account_use_case.dart` | UpdateAccountUseCase | Account update before unsupported balance adjustment | AccountApplicationService | No correction/balance-adjustment command covering request semantics | B | High; changing a balance-bearing account can persist before operation rejection |
| `lib/services/goal_activity_service.dart:addActivity/deleteActivity` | GoalActivityService | Goal history activity | GoalDetailsScreen, reserve dialog, reserved money screen, engine adapter | GoalTransferOperation covers transfer activity; reserve/release/cancel/complete equivalents are incomplete | B/F | High; do not remove without operation coverage |
| `lib/services/allocation_service.dart` | AllocationService | Legacy `allocations` box records | GoalAllocationService compatibility read and unknown legacy callers | PlanningEngine / HiveAllocationRepository for planning allocations | B | High; duplicate allocation stores are possible |
| `lib/services/reserved_money_service.dart` | ReservedMoneyService | `reserved_money` records | No production caller found | Planning allocation/projection model | B | High; independent reserved-money source conflicts with Rule 19 |
| `lib/services/goal_service.dart` | GoalService | Goal create/update/delete | Goal screens, development fixture | No single financial operation for goal lifecycle metadata | B | Medium; metadata may be safe, lifecycle actions with funding need planning/engine coverage |
| `lib/services/budget_service.dart` | BudgetService | Budget CRUD | Budget UI/service callers | No financial-engine operation required for planning policy | B | Low; not executed financial reality |
| `lib/services/commitment_service.dart` | CommitmentService | Commitment CRUD/archive/settlement metadata | Future action/debt workflows | CommitmentPaymentOperation only when actual payment executes | B | Medium; commitments must remain future state until execution |
| `lib/services/schedule_rule_service.dart` | ScheduleRuleService | Schedule rule CRUD | Future action/debt workflows | No engine operation; schedule is future intent | B | Low |
| `lib/services/schedule_occurrence_service.dart` | ScheduleOccurrenceService | Generated/completed schedule occurrences | CommitmentActionProvider | No engine operation; occurrence is scheduling state | B | Low |
| `lib/services/migration_service.dart` | MigrationService | Account compatibility corrections | Migration tests / startup migration path | No engine equivalent; controlled migration only | C | High; persisted-data migration requires its own validation/rollback gate |
| `lib/services/manual_reserve_application_service.dart` | ManualReserveApplicationService | Planning source display-name metadata | Planning UI | No financial operation; metadata only | B | Low |
| `lib/features/members/controllers/members_controller.dart` and `services/member_seeder.dart` | Member writers | Member records | Member UI/bootstrap | No financial operation; identity metadata | B | Low |
| `lib/main.dart` guarded actor test | App bootstrap diagnostic | Test transaction via `Box.add` | `runActorTest` development flag | None; remove/retain only as test diagnostic in a later cleanup gate | E | High if the flag is enabled outside development |
| `lib/services/ledger_stress_test_service.dart` and `ledger_sandbox_service.dart` | Development diagnostics | Direct transactions/ledger entries | Development/stress paths | Engine scenarios exist for normal operations; sandbox intentionally tests storage | E | Medium; must not become production wiring |
| `test/**` Hive setup/fixture writes and memory repositories | Test-only writers | Fixture accounts, transactions, ledger, schedules, allocations | Tests | N/A | E | Low |

## First safe migration

The reserved-goal transfer flow in `GoalDetailsScreen._executeTransfer` had an
exact canonical equivalent: `GoalTransferOperation`. Its existing planner
creates the transaction, journal entry, allocation release, and GoalActivity
in one engine execution plan. The UI now expresses that intent and no longer
coordinates these writes or compensating rollback itself.

The separate `GoalDetailsScreen._transferSavingGoalFunding` direct transaction
write remains a bypass. It must not be migrated to `GoalTransferOperation`
because it does not release an existing reservation; doing so would change
behavior.

## Checklist after this migration

- [x] Expense, income, transfer, correction, delete, opening balance, and
  commitment payment have canonical operations.
- [x] Reserved-goal transfer reaches the existing canonical operation.
- [x] Engine transaction, journal, allocation, and GoalActivity adapters are
  persistence-only writers.
- [ ] Legacy generic transaction writes are removed or explicitly routed by
  operation type.
- [ ] All GoalActivity reserve/release/lifecycle writers have equivalent
  canonical operations.
- [ ] Legacy allocation and ReservedMoney stores are reconciled.
- [ ] Account balance-adjustment semantics are supplied by an approved
  canonical operation.
- [ ] Ledger legacy CRUD callers are eliminated before Dual Writer Removal.

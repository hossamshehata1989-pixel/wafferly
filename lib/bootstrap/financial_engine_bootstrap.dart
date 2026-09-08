import 'package:hive/hive.dart';

import '../core/planning/bootstrap/planning_engine_bootstrap.dart';
import '../core/planning/infrastructure/repositories/memory_allocation_repository.dart'
    as planning_memory;
import '../core/planning/ports/allocation_repository.dart' as planning_ports;
import '../financial_engine/domain_guard/balance_domain_guard.dart';
import '../financial_engine/domain_guard/domain_guard_pipeline.dart';
import '../financial_engine/domain_guard/transfer_domain_guard.dart';
import '../financial_engine/engine/financial_operation_engine.dart';
import '../financial_engine/execution/create_allocation_mutation_handler.dart';
import '../financial_engine/execution/default_financial_executor.dart';
import '../financial_engine/execution/deletion_transaction_mutation_handler.dart';
import '../financial_engine/execution/goal_activity_mutation_handler.dart';
import '../financial_engine/execution/journal_entry_mutation_handler.dart';
import '../financial_engine/execution/memory_financial_unit_of_work.dart';
import '../financial_engine/execution/mutation_handler_registry.dart';
import '../financial_engine/execution/release_allocation_mutation_handler.dart';
import '../financial_engine/execution/update_transaction_mutation_handler.dart';
import '../financial_engine/handlers/create_transaction_mutation_handler.dart';
import '../financial_engine/idempotency/idempotency_guard.dart';
import '../financial_engine/integrity/default_financial_integrity_checker.dart';
import '../financial_engine/interpretation/default_financial_interpreter.dart';
import '../financial_engine/memory/memory_idempotency_store.dart';
import '../financial_engine/mutations/create_transaction_mutation.dart';
import '../financial_engine/mutations/deletion_transaction_mutation.dart';
import '../financial_engine/mutations/goal_activity_mutation.dart';
import '../financial_engine/mutations/journal_entry_mutation.dart';
import '../financial_engine/mutations/release_allocation_mutation.dart';
import '../financial_engine/mutations/update_transaction_mutation.dart';
import '../financial_engine/operations/create_allocation_mutation.dart';
import '../financial_engine/planning/account_mapping.dart';
import '../financial_engine/planning/chart_of_accounts.dart';
import '../financial_engine/planning/default_financial_planner.dart';
import '../infrastructure/adapters/allocation_adapter.dart';
import '../infrastructure/adapters/goal_activity_adapter.dart';
import '../infrastructure/hive/hive_balance_port.dart';
import '../financial_engine/adapters/hive_transaction_port.dart';
import '../infrastructure/memory/memory_allocation_repository.dart'
    as legacy_memory;
import '../infrastructure/memory/memory_journal_entry_repository.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/balance_service.dart';
import '../services/goal_activity_service.dart';
import '../services/ledger_projection_service.dart';
import 'financial_engine_context.dart';

final class FinancialEngineBootstrap {
  const FinancialEngineBootstrap._();

  static FinancialEngineContext create({
    required BalanceService balanceService,
    required Box<Transaction> transactionBox,
    planning_ports.AllocationRepository? allocationRepository,
  }) {
    final journalRepository = MemoryJournalEntryRepository();
    final idempotencyStore = MemoryIdempotencyStore();
    final idempotencyGuard = IdempotencyGuard(store: idempotencyStore);

    final journalHandler = JournalEntryMutationHandler(
      port: journalRepository,
    );

    final createAllocationRepository =
        legacy_memory.MemoryAllocationRepository();
    final createAllocationHandler = CreateAllocationMutationHandler(
      port: createAllocationRepository,
    );

    final transactionPort = HiveTransactionPort(transactionBox);
    final ledgerProjectionService = LedgerProjectionService();
    final createTransactionHandler = CreateTransactionMutationHandler(
      transactionPort,
      ledgerProjectionService,
    );

    final updateTransactionHandler = UpdateTransactionMutationHandler(
      port: transactionPort,
    );
    final deleteTransactionHandler = DeleteTransactionMutationHandler(
      transactionPort: transactionPort,
    );

    final balancePort = HiveBalancePort(balanceService: balanceService);
    final balanceGuard = BalanceDomainGuard(balancePort: balancePort);
    final transferGuard = TransferDomainGuard(
      accountService: AccountService(),
    );

    // Goal transfers release Planning allocations through the Planning Engine.
    // The injected repository is shared with the Planning read side when
    // available. Tests can inject the in-memory Planning repository.
    final planningAllocationRepository =
        allocationRepository ?? planning_memory.MemoryAllocationRepository();

    final planningEngine = PlanningEngineBootstrap.create(
      allocationRepository: planningAllocationRepository,
    );

    final allocationPort = AllocationAdapter(
      planningEngine: planningEngine,
    );
    final releaseAllocationHandler = ReleaseAllocationMutationHandler(
      port: allocationPort,
    );

    final goalActivityPort = GoalActivityAdapter(
      service: GoalActivityService(),
    );
    final goalActivityHandler = GoalActivityMutationHandler(
      port: goalActivityPort,
    );

    final registry = MutationHandlerRegistry(
      handlers: {
        JournalEntryMutation: journalHandler,
        CreateAllocationMutation: createAllocationHandler,
        CreateTransactionMutation: createTransactionHandler,
        UpdateTransactionMutation: updateTransactionHandler,
        DeleteTransactionMutation: deleteTransactionHandler,
        ReleaseAllocationMutation: releaseAllocationHandler,
        GoalActivityMutation: goalActivityHandler,
      },
    );

    final executor = DefaultFinancialExecutor(
      registry: registry,
      unitOfWork: const MemoryFinancialUnitOfWork(),
    );

    final planner = DefaultFinancialPlanner(
      chartOfAccounts: const ChartOfAccounts(
        mappings: [
          AccountMapping(
  categoryId: 'dailyTransport',
            accountId: 'expense_account',
          ),
          AccountMapping(
            categoryId: 'salary',
            accountId: 'income_account',
          ),
        ],
      ),
      transactionLookupPort: transactionPort,
    );

    final engine = FinancialOperationEngine(
      interpreter: const DefaultFinancialInterpreter(),
      domainGuardPipeline: DomainGuardPipeline(
        guards: [transferGuard, balanceGuard],
      ),
      planner: planner,
      integrityChecker: const DefaultFinancialIntegrityChecker(),
      executor: executor,
      idempotencyGuard: idempotencyGuard,
    );

    return FinancialEngineContext(
      engine: engine,
      repository: journalRepository,
      allocationRepository: createAllocationRepository,
      balancePort: balancePort,
    );
  }
}

import 'package:hive/hive.dart';

import '../core/money/money.dart';
import '../core/planning/entities/allocation.dart';
import '../core/planning/ports/allocation_repository.dart';
import '../core/planning/value_objects/planning_source_type.dart';
import '../financial_engine/adapters/hive_transaction_port.dart';
import '../financial_engine/adapters/hive_correction_port.dart';
import '../financial_engine/adapters/hive_invalidation_port.dart';
import '../financial_engine/engine/financial_operation_engine.dart';
import '../financial_engine/execution/default_financial_executor.dart';
import '../financial_engine/execution/journal_entry_mutation_handler.dart';
import '../financial_engine/execution/memory_financial_unit_of_work.dart';
import '../financial_engine/execution/mutation_handler_registry.dart';
import '../financial_engine/handlers/create_transaction_mutation_handler.dart';
import '../financial_engine/handlers/create_correction_mutation_handler.dart';
import '../financial_engine/handlers/invalidate_transaction_mutation_handler.dart';
import '../financial_engine/idempotency/idempotency_guard.dart';
import '../financial_engine/integrity/default_financial_integrity_checker.dart';
import '../financial_engine/interpretation/default_financial_interpreter.dart';
import '../financial_engine/memory/memory_idempotency_store.dart';
import '../financial_engine/idempotency/hive_idempotency_store.dart';
import '../financial_engine/mutations/create_transaction_mutation.dart';
import '../financial_engine/mutations/create_correction_mutation.dart';
import '../financial_engine/mutations/invalidate_transaction_mutation.dart';
import '../financial_engine/mutations/journal_entry_mutation.dart';
import '../financial_engine/operations/create_allocation_mutation.dart';
import '../financial_engine/ports/create_allocation_port.dart';
import '../financial_engine/memory/memory_correction_port.dart';
import '../financial_engine/memory/memory_invalidation_port.dart';
import '../financial_engine/planning/account_mapping.dart';
import '../financial_engine/planning/chart_of_accounts.dart';
import '../financial_engine/planning/default_financial_planner.dart';
import '../financial_engine/domain_guard/balance_domain_guard.dart';
import '../financial_engine/domain_guard/goal_saving_transfer_domain_guard.dart';
import '../services/account_service.dart';
import '../financial_engine/domain_guard/domain_guard_pipeline.dart';
import '../infrastructure/hive/hive_balance_port.dart';
import '../infrastructure/memory/memory_journal_entry_repository.dart';
import '../models/transaction.dart';
import '../services/balance_service.dart';
import '../services/ledger_projection_service.dart';
import 'financial_engine_context.dart';
import '../financial_engine/execution/create_allocation_mutation_handler.dart';
import '../financial_engine/execution/release_allocation_mutation_handler.dart';
import '../financial_engine/execution/goal_activity_mutation_handler.dart';
import '../infrastructure/adapters/allocation_adapter.dart';
import '../infrastructure/adapters/goal_activity_adapter.dart';
import '../financial_engine/mutations/release_allocation_mutation.dart';
import '../financial_engine/mutations/goal_activity_mutation.dart';
import '../core/planning/bootstrap/planning_engine_bootstrap.dart';
import '../services/goal_activity_service.dart';

/// Bridges the legacy Financial Engine allocation mutation to the
/// Planning Engine's canonical AllocationRepository.
///
/// The Financial Engine mutation still carries a double for compatibility.
/// The Planning domain stores Money, so the conversion happens here.
final class CreateAllocationPortAdapter implements CreateAllocationPort {
  final AllocationRepository repository;

  const CreateAllocationPortAdapter({required this.repository});

  @override
  Future<void> createAllocation(CreateAllocationMutation mutation) async {
    final allocation = Allocation(
      id: 'allocation-${mutation.goalId}-${DateTime.now().microsecondsSinceEpoch}',
      sourceId: mutation.goalId,
      sourceType: PlanningSourceType.goal,
      accountId: mutation.accountId,
      amount: Money.fromDouble(mutation.amount),
      createdAt: DateTime.now(),
    );

    await repository.create(allocation);
  }
}

final class FinancialEngineBootstrap {
  const FinancialEngineBootstrap._();

  static FinancialEngineContext create({
    required BalanceService balanceService,
    required Box<Transaction> transactionBox,
    Box<Map>? correctionBox,
    Box<Map>? invalidationBox,
    Box<Map>? idempotencyBox,
    AllocationRepository? allocationRepository,
  }) {
    final sharedAllocationRepository =
        allocationRepository ?? _FallbackAllocationRepository();

    final repository = MemoryJournalEntryRepository();
    final idempotencyStore = idempotencyBox != null
        ? HiveIdempotencyStore(idempotencyBox)
        : MemoryIdempotencyStore();
    final idempotencyGuard = IdempotencyGuard(store: idempotencyStore);

    final journalHandler = JournalEntryMutationHandler(port: repository);

    final createAllocationPort = CreateAllocationPortAdapter(
      repository: sharedAllocationRepository,
    );

    final createAllocationHandler = CreateAllocationMutationHandler(
      port: createAllocationPort,
    );

    // Goal transfer releases the reservation through the same
    // Planning Engine and the same AllocationRepository.
    final planningEngine = PlanningEngineBootstrap.create(
      allocationRepository: sharedAllocationRepository,
    );

    final allocationPort = AllocationAdapter(
      planningEngine: planningEngine,
      allocationRepository: sharedAllocationRepository,
    );

    final releaseAllocationHandler = ReleaseAllocationMutationHandler(
      port: allocationPort,
    );

    // Goal transfer also records immutable goal history.
    final goalActivityPort = GoalActivityAdapter(
      service: GoalActivityService(),
    );

    final goalActivityHandler = GoalActivityMutationHandler(
      port: goalActivityPort,
    );

    final transactionPort = HiveTransactionPort(transactionBox);
    final correctionPort = correctionBox != null
        ? HiveCorrectionPort(correctionBox)
        : MemoryCorrectionPort();
    final invalidationPort = invalidationBox != null
        ? HiveInvalidationPort(invalidationBox)
        : MemoryInvalidationPort();
    final ledgerProjectionService = LedgerProjectionService();

    final createTransactionHandler = CreateTransactionMutationHandler(
      transactionPort,
      ledgerProjectionService,
    );

    final createCorrectionHandler = CreateCorrectionMutationHandler(
      correctionPort: correctionPort,
      transactionPort: transactionPort,
      ledgerProjectionService: ledgerProjectionService,
    );

    final invalidateTransactionHandler =
        InvalidateTransactionMutationHandler(
          invalidationPort: invalidationPort,
          ledgerProjectionService: ledgerProjectionService,
        );

    final balancePort = HiveBalancePort(balanceService: balanceService);
    final balanceGuard = BalanceDomainGuard(balancePort: balancePort);
    final goalSavingTransferGuard = GoalSavingTransferDomainGuard(
      accountService: AccountService(),
    );

    final registry = MutationHandlerRegistry(
      handlers: {
        JournalEntryMutation: journalHandler,
        CreateAllocationMutation: createAllocationHandler,
        CreateTransactionMutation: createTransactionHandler,
        CreateCorrectionMutation: createCorrectionHandler,
        InvalidateTransactionMutation: invalidateTransactionHandler,
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
          AccountMapping(categoryId: 'dailyTransport', accountId: 'expense_account'),
          AccountMapping(categoryId: 'salary', accountId: 'income_account'),
        ],
      ),
      transactionLookupPort: transactionPort,
    );

    final engine = FinancialOperationEngine(
      interpreter: const DefaultFinancialInterpreter(),
      domainGuardPipeline: DomainGuardPipeline(
        guards: [goalSavingTransferGuard, balanceGuard],
      ),
      planner: planner,
      integrityChecker: const DefaultFinancialIntegrityChecker(),
      executor: executor,
      idempotencyGuard: idempotencyGuard,
    );

    return FinancialEngineContext(
      engine: engine,
      repository: repository,
      allocationRepository: sharedAllocationRepository,
      balancePort: balancePort,
    );
  }
}

/// Local fallback used only when FinancialEngineBootstrap is created without
/// an injected Planning repository (for older unit tests).
///
/// Production wiring in main.dart must inject the canonical repository.
final class _FallbackAllocationRepository implements AllocationRepository {
  final Map<String, Allocation> _storage = {};

  @override
  Future<void> create(Allocation allocation) async {
    _storage[allocation.id] = allocation;
  }

  @override
  Future<void> update(Allocation allocation) async {
    _storage[allocation.id] = allocation;
  }

  @override
  Future<Allocation?> findById(String allocationId) async {
    return _storage[allocationId];
  }

  @override
  Future<List<Allocation>> findBySource(String sourceId) async {
    return _storage.values.where((a) => a.sourceId == sourceId).toList();
  }

  @override
  Future<List<Allocation>> findByAccount(String accountId) async {
    return _storage.values.where((a) => a.accountId == accountId).toList();
  }

  @override
  Future<List<Allocation>> findActive() async {
    return _storage.values.where((a) => a.status.index == 1).toList();
  }

  @override
  Future<void> delete(String allocationId) async {
    _storage.remove(allocationId);
  }

  @override
  Future<Allocation?> findActiveBySource(String sourceId) async {
    try {
      return _storage.values.firstWhere(
        (allocation) =>
            allocation.sourceId == sourceId && allocation.status.index == 1,
      );
    } catch (_) {
      return null;
    }
  }
}

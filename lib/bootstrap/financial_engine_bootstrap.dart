import '../financial_engine/domain_guard/balance_domain_guard.dart';
import '../financial_engine/domain_guard/domain_guard_pipeline.dart';
import '../financial_engine/engine/financial_operation_engine.dart';
import '../financial_engine/execution/create_allocation_mutation_handler.dart';
import '../financial_engine/execution/default_financial_executor.dart';
import '../financial_engine/execution/journal_entry_mutation_handler.dart';
import '../financial_engine/execution/memory_financial_unit_of_work.dart';
import '../financial_engine/execution/mutation_handler_registry.dart';
import '../financial_engine/idempotency/idempotency_guard.dart';
import '../financial_engine/integrity/default_financial_integrity_checker.dart';
import '../financial_engine/interpretation/default_financial_interpreter.dart';
import '../financial_engine/memory/memory_idempotency_store.dart';
import '../financial_engine/operations/create_allocation_mutation.dart';
import '../financial_engine/planning/account_mapping.dart';
import '../financial_engine/planning/chart_of_accounts.dart';
import '../financial_engine/planning/default_financial_planner.dart';
import '../financial_engine/mutations/journal_entry_mutation.dart';
import '../infrastructure/memory/memory_allocation_repository.dart';
import '../infrastructure/memory/memory_journal_entry_repository.dart';
import 'financial_engine_context.dart';
import '../services/balance_service.dart';
import '../infrastructure/hive/hive_balance_port.dart';
import '../financial_engine/adapters/hive_transaction_port.dart';
import '../financial_engine/handlers/create_transaction_mutation_handler.dart';
import '../financial_engine/mutations/create_transaction_mutation.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../financial_engine/mutations/update_transaction_mutation.dart';
import '../financial_engine/execution/update_transaction_mutation_handler.dart';
import '../financial_engine/mutations/deletion_transaction_mutation.dart';
import '../financial_engine/mutations/deletion_transaction_mutation_handler.dart';

final class FinancialEngineBootstrap {
  const FinancialEngineBootstrap._();

  static FinancialEngineContext create({
    required BalanceService balanceService,
    required Box<Transaction> transactionBox,
  }) {
    final repository = MemoryJournalEntryRepository();

    final idempotencyStore = MemoryIdempotencyStore();

    final idempotencyGuard = IdempotencyGuard(store: idempotencyStore);

    final journalHandler = JournalEntryMutationHandler(port: repository);

    final createAllocationRepository = MemoryAllocationRepository();

    final createAllocationHandler = CreateAllocationMutationHandler(
      port: createAllocationRepository,
    );
    final transactionPort = HiveTransactionPort(transactionBox);

    final createTransactionHandler = CreateTransactionMutationHandler(
      transactionPort,
    );

    final updateTransactionHandler = UpdateTransactionMutationHandler(
      port: transactionPort,
    );

    final deleteTransactionHandler = DeleteTransactionMutationHandler(
      transactionPort: transactionPort,
    );

    final balancePort = HiveBalancePort(balanceService: balanceService);
    final balanceGuard = BalanceDomainGuard(balancePort: balancePort);

    final registry = MutationHandlerRegistry(
      handlers: {
        JournalEntryMutation: journalHandler,
        CreateAllocationMutation: createAllocationHandler,
        CreateTransactionMutation: createTransactionHandler,
        UpdateTransactionMutation: updateTransactionHandler,
        DeleteTransactionMutation: deleteTransactionHandler,
      },
    );

    final executor = DefaultFinancialExecutor(
      registry: registry,
      unitOfWork: const MemoryFinancialUnitOfWork(),
    );

    final planner = DefaultFinancialPlanner(
      chartOfAccounts: const ChartOfAccounts(
        mappings: [
          AccountMapping(categoryId: 'transport', accountId: 'expense_account'),
          AccountMapping(categoryId: 'salary', accountId: 'income_account'),
        ],
      ),
      transactionLookupPort: transactionPort,
    );
    final engine = FinancialOperationEngine(
      interpreter: const DefaultFinancialInterpreter(),
      domainGuardPipeline: DomainGuardPipeline(guards: [balanceGuard]),
      planner: planner,
      integrityChecker: const DefaultFinancialIntegrityChecker(),
      executor: executor,
      idempotencyGuard: idempotencyGuard,
    );

    return FinancialEngineContext(
      engine: engine,
      repository: repository,
      allocationRepository: createAllocationRepository,
      balancePort: balancePort,
    );
  }
}

import '../financial_engine/domain_guard/domain_guard_pipeline.dart';
import '../financial_engine/engine/financial_operation_engine.dart';
import '../financial_engine/execution/default_financial_executor.dart';
import '../financial_engine/execution/journal_entry_mutation_handler.dart';
import '../financial_engine/execution/memory_financial_unit_of_work.dart';
import '../financial_engine/execution/mutation_handler_registry.dart';
import '../financial_engine/integrity/default_financial_integrity_checker.dart';
import '../financial_engine/interpretation/default_financial_interpreter.dart';
import '../financial_engine/planning/account_mapping.dart';
import '../financial_engine/planning/chart_of_accounts.dart';
import '../financial_engine/planning/default_financial_planner.dart';
import '../financial_engine/planning/journal_entry_mutation.dart';
import '../infrastructure/memory/memory_journal_entry_repository.dart';
import 'financial_engine_context.dart';

final class FinancialEngineBootstrap {
  const FinancialEngineBootstrap._();

  static FinancialEngineContext create() {
    final repository = MemoryJournalEntryRepository();

    final handler = JournalEntryMutationHandler(repository: repository);

    final registry = MutationHandlerRegistry(
      handlers: {JournalEntryMutation: handler},
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
    );

    final engine = FinancialOperationEngine(
      interpreter: const DefaultFinancialInterpreter(),
      domainGuardPipeline: const DomainGuardPipeline(),
      planner: planner,
      integrityChecker: const DefaultFinancialIntegrityChecker(),
      executor: executor,
    );

    return FinancialEngineContext(engine: engine, repository: repository);
  }
}

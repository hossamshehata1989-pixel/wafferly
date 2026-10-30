import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/financial_engine/execution/default_financial_executor.dart';
import 'package:wafferly/financial_engine/execution/financial_mutation_handler.dart';
import 'package:wafferly/financial_engine/execution/financial_transaction_context.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/execution/mutation_handler_registry.dart';
import 'package:wafferly/financial_engine/execution/journal_entry_mutation_handler.dart';
import 'package:wafferly/financial_engine/mutations/journal_entry_mutation.dart';
import 'package:wafferly/financial_engine/planning/financial_execution_plan.dart';
import 'package:wafferly/financial_engine/planning/financial_mutation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/infrastructure/memory/memory_journal_entry_repository.dart';

void main() {
  test(
    'rolling back a second journal entry with the same ID preserves the first entry',
    () async {
      final repository = MemoryJournalEntryRepository();
      final executor = _buildExecutor(repository);

      final firstMutation = JournalEntryMutation(
        journalEntryId: 'journal-1',
        description: 'first-successful-entry',
        lines: const [],
      );
      final firstResult = await executor.execute(
        FinancialExecutionPlan(
          planId: 'plan-first-success',
          operationId: 'operation-first-success',
          idempotencyKey: 'key-first-success',
          mutations: <FinancialMutation>[firstMutation],
        ),
      );

      expect(firstResult, isA<OperationSucceeded>());
      expect(repository.entries, hasLength(1));
      expect(repository.entries.single, same(firstMutation));

      final secondMutation = JournalEntryMutation(
        journalEntryId: 'journal-1',
        description: 'second-failing-entry',
        lines: const [],
      );
      final secondResult = await executor.execute(
        FinancialExecutionPlan(
          planId: 'plan-second-failure',
          operationId: 'operation-second-failure',
          idempotencyKey: 'key-second-failure',
          mutations: <FinancialMutation>[secondMutation, const _FailMutation()],
        ),
      );

      expect(secondResult, isA<OperationFailed>());
      expect(repository.entries, hasLength(1));
      expect(repository.entries.single, same(firstMutation));
      expect(repository.entries.single.description, 'first-successful-entry');
      expect(repository.entries, isNot(contains(secondMutation)));
    },
  );
}

DefaultFinancialExecutor _buildExecutor(
  MemoryJournalEntryRepository repository,
) {
  return DefaultFinancialExecutor(
    registry: MutationHandlerRegistry(
      handlers: {
        JournalEntryMutation: JournalEntryMutationHandler(port: repository),
        _FailMutation: _FailHandler(),
      },
    ),
    unitOfWork: const MemoryFinancialUnitOfWork(),
  );
}

final class _FailMutation extends FinancialMutation {
  const _FailMutation();
}

final class _FailHandler implements FinancialMutationHandler<_FailMutation> {
  @override
  Future<void> execute(
    _FailMutation mutation,
    FinancialTransactionContext context,
  ) async {
    throw StateError('Intentional failure after journal persistence');
  }
}

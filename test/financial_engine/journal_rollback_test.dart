import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/financial_engine/execution/default_financial_executor.dart';
import 'package:wafferly/financial_engine/execution/financial_mutation_handler.dart';
import 'package:wafferly/financial_engine/execution/financial_transaction_context.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/execution/mutation_handler_registry.dart';
import 'package:wafferly/financial_engine/mutations/journal_entry_mutation.dart';
import 'package:wafferly/financial_engine/planning/financial_execution_plan.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/infrastructure/memory/memory_journal_entry_repository.dart';
import 'package:wafferly/financial_engine/execution/journal_entry_mutation_handler.dart';
import 'package:wafferly/financial_engine/planning/financial_mutation.dart';
void main() {
  test(
    'journal entry is rolled back when a later mutation fails',
    () async {
      final journalRepository = MemoryJournalEntryRepository();

      final journalHandler = JournalEntryMutationHandler(
        port: journalRepository,
      );

      final registry = MutationHandlerRegistry(
        handlers: {
          JournalEntryMutation: journalHandler,
          _FailMutation: _FailHandler(),
        },
      );

      final executor = DefaultFinancialExecutor(
        registry: registry,
        unitOfWork: const MemoryFinancialUnitOfWork(),
      );

      final journalMutation = JournalEntryMutation(
        journalEntryId: 'journal-rollback-001',
        description: 'Rollback Test',
        lines: const [],
      );

      final plan = FinancialExecutionPlan(
        planId: 'journal-rollback-plan',
        operationId: 'journal-rollback-operation',
        idempotencyKey: 'journal-rollback-test',
        mutations: [
          journalMutation,
          const _FailMutation(),
        ],
      );

      final result = await executor.execute(plan);

      expect(result, isA<OperationFailed>());
      expect(journalRepository.entries, isEmpty);
    },
  );
}

final class _FailMutation extends FinancialMutation {
  const _FailMutation();
}

final class _FailHandler
    implements FinancialMutationHandler<_FailMutation> {
       @override
  Future<void> execute(
    _FailMutation mutation,
    FinancialTransactionContext context,
  ) async {
    throw StateError('Intentional failure after journal persistence');
  }
}
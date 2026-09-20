import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/financial_engine/execution/default_financial_executor.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/execution/mutation_handler_registry.dart';
import 'package:wafferly/financial_engine/planning/financial_execution_plan.dart';
import 'package:wafferly/financial_engine/planning/financial_mutation.dart';
import 'package:wafferly/financial_engine/execution/financial_mutation_handler.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';

final class _PersistMutation extends DomainMutation {
  final String value;

  const _PersistMutation(this.value);
}

final class _FailMutation extends DomainMutation {
  const _FailMutation();
}

final class _PersistHandler
    implements FinancialMutationHandler<_PersistMutation> {
  final List<String> storage;

  const _PersistHandler(this.storage);

  @override
  Future<void> execute(_PersistMutation mutation) async {
    storage.add(mutation.value);
  }
}

final class _FailHandler
    implements FinancialMutationHandler<_FailMutation> {
  const _FailHandler();

  @override
  Future<void> execute(_FailMutation mutation) async {
    throw StateError('Simulated mutation failure');
  }
}

void main() {
  test(
    'failed execution rolls back mutations already persisted in the plan',
    () async {
      final storage = <String>[];

      final registry = MutationHandlerRegistry(
        handlers: {
          _PersistMutation: _PersistHandler(storage),
          _FailMutation: const _FailHandler(),
        },
      );

      final executor = DefaultFinancialExecutor(
        registry: registry,
        unitOfWork: const MemoryFinancialUnitOfWork(),
      );

      const plan = FinancialExecutionPlan(
        planId: 'atomicity-test-plan',
        operationId: 'atomicity-test-operation',
        idempotencyKey: 'atomicity-test-key',
        mutations: [
          _PersistMutation('first-mutation'),
          _FailMutation(),
        ],
      );

      final result = await executor.execute(plan);

      expect(result, isA<OperationFailed>());

      // Atomicity requirement:
      // if any mutation fails, earlier mutations must not remain persisted.
      expect(storage, isEmpty);
    },
  );
}
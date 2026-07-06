import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/create_goal_allocation_operation.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';

void main() {
  test('CreateGoalAllocationOperation executes successfully', () async {
    final context = FinancialEngineBootstrap.create();

    final result = await context.engine.execute(
      CreateGoalAllocationOperation(
        accountId: 'cash',
        goalId: 'goal-1',
        amount: 500,
        occurredAt: DateTime.now(),
        resolution: Resolution.execute,
      ),
      const ExecutionContext(idempotencyKey: 'allocation-test-1'),
    );
    if (result is OperationFailed) {
      print(result.error);
    }
    expect(result, isA<OperationSucceeded>());

    expect(context.allocationRepository.allocations.length, 1);
  });
}

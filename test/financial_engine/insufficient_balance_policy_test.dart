import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/goal_transfer_operation.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';

void main() {
  test('Goal transfer larger than balance is blocked by policy', () async {
    final context = FinancialEngineBootstrap.create();

    // Simulate low balance
    context.balancePort.balances['cash'] = 100;

    final result = await context.engine.execute(
      GoalTransferOperation(
        sourceAccountId: 'cash',
        savingsAccountId: 'saving',
        goalId: 'goal-1',
        amount: 1000,
        occurredAt: DateTime.now(),
        resolution: Resolution.execute,
      ),
      const ExecutionContext(idempotencyKey: 'insufficient-balance-test'),
    );

    expect(result, isA<OperationFailed>());

    final failed = result as OperationFailed;

    expect(failed.error, contains('Confirmation'));
  });
}

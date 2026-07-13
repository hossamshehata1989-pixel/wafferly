import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/goal_transfer_operation.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';

void main() {
  test('Goal transfer creates accounting and goal mutations', () async {
    final context = FinancialEngineBootstrap.create();

    final operation = GoalTransferOperation(
      sourceAccountId: 'cash',
      savingsAccountId: 'saving',
      goalId: 'goal-1',
      amount: 500,
      occurredAt: DateTime.now(),
      resolution: Resolution.execute,
    );

    const executionContext = ExecutionContext(
      idempotencyKey: 'goal-transfer-1',
    );

    final result = await context.engine.execute(operation, executionContext);

    expect(result, isNotNull);

    final entries = context.repository.entries;

    expect(entries.length, 1);

    expect(entries.single.lines.length, 2);
  });
}

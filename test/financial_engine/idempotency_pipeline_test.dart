import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/expense_operation.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';

void main() {
  test('Same idempotency key executes only once', () async {
    final context = FinancialEngineBootstrap.create();

    final operation = ExpenseOperation(
      sourceAccountId: 'cash',
      categoryId: 'transport',
      amount: 100,
      occurredAt: DateTime.now(),
      resolution: Resolution.execute,
    );

    const executionContext = ExecutionContext(idempotencyKey: 'same-key');

    final result1 = await context.engine.execute(operation, executionContext);

    final result2 = await context.engine.execute(operation, executionContext);

    expect(identical(result1, result2), isTrue);
  });
}

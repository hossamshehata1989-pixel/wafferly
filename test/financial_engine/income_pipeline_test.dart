import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/financial_engine/operations/income_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';

void main() {
  test('Income operation creates one journal entry', () async {
    final context = FinancialEngineBootstrap.create();

    final result = await context.engine.execute(
      IncomeOperation(
        destinationAccountId: 'wallet',
        categoryId: 'salary',
        amount: 5000,
        occurredAt: DateTime.now(),
      ),
      const ExecutionContext(idempotencyKey: 'income-test'),
    );

    expect(result, isA<OperationSucceeded>());

    expect(context.repository.entries.length, 1);

    final entry = context.repository.entries.single;

    expect(entry.lines.length, 2);

    final debit = entry.lines.first;
    final credit = entry.lines.last;

    expect(debit.debit, 5000);

    expect(credit.credit, 5000);
  });
}

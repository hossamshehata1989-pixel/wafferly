import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/financial_engine/operations/expense_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';

void main() {
  test('Expense operation creates one journal entry', () async {
    final context = FinancialEngineBootstrap.create();

    final result = await context.engine.execute(
      ExpenseOperation(
        sourceAccountId: 'wallet',
        categoryId: 'transport',
        amount: 50,
        occurredAt: DateTime.now(),
      ),
    );

    expect(result, isA<OperationSucceeded>());

    expect(context.repository.entries.length, 1);

    final entry = context.repository.entries.single;

    expect(entry.lines.length, 2);

    final debit = entry.lines.first;
    final credit = entry.lines.last;

    expect(debit.debit, 50);

    expect(credit.credit, 50);
  });
}

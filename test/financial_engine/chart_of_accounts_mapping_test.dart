import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/financial_engine/planning/account_mapping.dart';
import 'package:wafferly/financial_engine/planning/chart_of_accounts.dart';

void main() {
  test('ChartOfAccounts does not silently fall back for an unmapped category',
      () {
    const chart = ChartOfAccounts(
      mappings: [
        AccountMapping(categoryId: 'salary', accountId: 'income_account'),
      ],
    );

    expect(chart.accountForCategory('salary'), 'income_account');
    expect(chart.accountForCategory('unknown-income-category'), isNull);
    expect(
      () => chart.requireAccountForCategory('unknown-income-category'),
      throwsA(isA<MissingChartOfAccountsMappingException>()),
    );
  });

  test('ChartOfAccounts rejects duplicate category mappings', () {
    const chart = ChartOfAccounts(
      mappings: [
        AccountMapping(categoryId: 'food', accountId: 'expense-a'),
        AccountMapping(categoryId: 'food', accountId: 'expense-b'),
      ],
    );

    expect(
      () => chart.accountForCategory('food'),
      throwsA(isA<DuplicateChartOfAccountsMappingException>()),
    );
  });

}

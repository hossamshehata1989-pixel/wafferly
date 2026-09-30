import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const screens = <String>[
    'lib/screens/accounts/liabilities/money_you_owe_screen.dart',
    'lib/screens/accounts/liabilities/liability_category_screen.dart',
    'lib/screens/accounts/liabilities/liability_account_details_screen.dart',
    'lib/screens/accounts/liabilities/credit_card_account_details_screen.dart',
    'lib/screens/accounts/add_credit_card/add_credit_card_screen.dart',
  ];

  test('liability UI does not bypass data-access boundaries', () {
    for (final path in screens) {
      final content = File(path).readAsStringSync();

      expect(content, isNot(contains("Hive.box(")), reason: path);
      expect(content, isNot(contains("package:hive")), reason: path);
      expect(content, isNot(contains('BalanceService()')), reason: path);
      expect(content, isNot(contains('.getBalance(')), reason: path);
    }
  });

  test('liability UI uses responsive project helpers', () {
    for (final path in screens) {
      final content = File(path).readAsStringSync();
      expect(content, contains('ResponsiveMetrics'), reason: path);
    }
  });

  test('liability UI uses the shared Wafferly form/action language', () {
    final addCard = File(
      'lib/screens/accounts/add_credit_card/add_credit_card_screen.dart',
    ).readAsStringSync();

    expect(addCard, contains('WafferlyTextField'));
    expect(addCard, contains('WafferlyDropdown'));
    expect(addCard, contains('WafferlyButton'));
    expect(addCard, contains('WafferlyFormSection'));
  });

  test('workflow-owned liability categories do not route to generic account CRUD', () {
    final category = File(
      'lib/screens/accounts/liabilities/liability_category_screen.dart',
    ).readAsStringSync();

    expect(category, isNot(contains('AddAccountScreen')));
    expect(category, isNot(contains('SectionType.liabilities')));
  });
}

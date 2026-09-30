import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Money You Owe defines liability categories and dedicated detail routing', () {
    final moneyOwe = File(
      'lib/screens/accounts/liabilities/money_you_owe_screen.dart',
    ).readAsStringSync();
    final category = File(
      'lib/screens/accounts/liabilities/liability_category_screen.dart',
    ).readAsStringSync();
    final categoryModel = File(
      'lib/models/enums/liability_category.dart',
    ).readAsStringSync();
    final creditDetails = File(
      'lib/screens/accounts/liabilities/credit_card_account_details_screen.dart',
    ).readAsStringSync();
    final navigator = File(
      'lib/screens/accounts/navigation/accounts_navigator.dart',
    ).readAsStringSync();
    final genericDetails = File(
      'lib/screens/accounts/liabilities/liability_account_details_screen.dart',
    ).readAsStringSync();

    for (final key in [
      't.creditCards',
      't.loans',
      't.installmentsBnpl',
      't.borrowedMoney',
    ]) {
      expect(moneyOwe, contains(key));
    }

    expect(category, contains('LiabilityCategory'));
    expect(categoryModel, contains('enum LiabilityCategory'));
    expect(category, contains('t.liabilityCategoryAlwaysVisible'));
    expect(creditDetails, contains('t.creditExposure'));
    expect(creditDetails, contains('projection.outstanding'));
    expect(creditDetails, contains('projection.available'));
    expect(navigator, contains('showCreditCardDetails'));
    expect(navigator, contains('showLoanDetails'));
    expect(navigator, contains('showInstallmentDetails'));
    expect(navigator, contains('showBorrowedMoneyDetails'));
    expect(genericDetails, contains('LiabilityAccountDetailsScreen'));
  });
}

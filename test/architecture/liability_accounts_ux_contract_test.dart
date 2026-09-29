import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Money You Owe defines all liability categories and dedicated detail routing', () {
    final moneyOwe = File('lib/screens/accounts/liabilities/money_you_owe_screen.dart').readAsStringSync();
    final category = File('lib/screens/accounts/liabilities/liability_category_screen.dart').readAsStringSync();
    final creditDetails = File('lib/screens/accounts/liabilities/credit_card_account_details_screen.dart').readAsStringSync();
    final navigator = File('lib/screens/accounts/navigation/accounts_navigator.dart').readAsStringSync();

    for (final label in [
      'Credit Cards',
      'Loans',
      'Installments / BNPL',
      'Borrowed Money',
    ]) {
      expect(moneyOwe, contains(label));
    }

    expect(category, contains('enum LiabilityCategory'));
    expect(category, contains('No \\${spec.title.toLowerCase()} yet'));
    expect(creditDetails, contains('Credit Exposure'));
    expect(creditDetails, contains('Outstanding'));
    expect(creditDetails, contains('Available'));
    expect(navigator, contains('showCreditCardDetails'));
    expect(navigator, contains('showLiabilityAccountDetails'));
  });
}

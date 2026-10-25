import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('financing conversion requires an explicit effective date', () {
    final service = File(
      'lib/application/credit_card/credit_card_financing_application_service.dart',
    ).readAsStringSync();

    expect(service, contains('required DateTime effectiveDate'));
    expect(service, contains('effectiveDate: effectiveDate'));
    expect(service, contains('createdAt: now'));
  });

  test('installment purchases from the outset use the original charge date', () {
    final controller = File(
      'lib/controllers/transaction_entry_controller.dart',
    ).readAsStringSync();
    final cardEntry = File(
      'lib/screens/accounts/liabilities/credit_card_transaction_entry_screen.dart',
    ).readAsStringSync();

    expect(controller, contains('effectiveDate: charge.date'));
    expect(cardEntry, contains('effectiveDate: tx.date'));
    expect(cardEntry, contains('_defaultFirstPaymentDate(_date)'));
    expect(cardEntry, contains('_defaultFirstPaymentDate(value)'));
  });

  test('converting an existing purchase uses the actual conversion date', () {
    final conversionScreen = File(
      'lib/screens/accounts/liabilities/credit_card_installment_conversion_screen.dart',
    ).readAsStringSync();

    expect(conversionScreen, contains('final conversionEffectiveDate = DateTime.now()'));
    expect(conversionScreen, contains('effectiveDate: conversionEffectiveDate'));
    expect(conversionScreen, contains('_defaultFirstDueDate(conversionEffectiveDate)'));
  });

  test('all first-due-date defaults go through the shared card-cycle policy', () {
    final policy = File(
      'lib/application/credit_card/credit_card_first_due_date_policy.dart',
    ).readAsStringSync();
    final paymentSheet = File(
      'lib/widgets/expense_entry/payment_method_sheet.dart',
    ).readAsStringSync();
    final cardEntry = File(
      'lib/screens/accounts/liabilities/credit_card_transaction_entry_screen.dart',
    ).readAsStringSync();
    final conversionScreen = File(
      'lib/screens/accounts/liabilities/credit_card_installment_conversion_screen.dart',
    ).readAsStringSync();

    expect(policy, contains('statementCloseDateForCharge'));
    expect(paymentSheet, contains('CreditCardFirstDueDatePolicy.defaultFirstDueDate'));
    expect(cardEntry, contains('CreditCardFirstDueDatePolicy.defaultFirstDueDate'));
    expect(conversionScreen, contains('CreditCardFirstDueDatePolicy.defaultFirstDueDate'));
  });
}

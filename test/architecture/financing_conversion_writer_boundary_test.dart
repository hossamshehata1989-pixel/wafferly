import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('financing conversion does not directly write financial truth', () {
    final file = File(
      'lib/financing/domain/credit_card_financing_conversion.dart',
    );
    final source = file.readAsStringSync();

    expect(source, isNot(contains('transactions.put(')));
    expect(source, isNot(contains('transactions.delete(')));
    expect(source, isNot(contains('accounts.put(')));
    expect(source, isNot(contains('accounts.delete(')));
    expect(source, isNot(contains('financial_idempotency')));
    expect(source, isNot(contains('FinancialOperationEngine')));
    expect(source, contains('contracts.put('));
    expect(source, contains('schedules.put('));
    expect(source, contains('installments.put('));
    expect(source, contains('conversionEvents.put('));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';

void main() {
  test('credit card profile preserves configuration needed by account details', () {
    final profile = CreditCardProfile.fromMoney(
      id: 'profile-1',
      accountId: 'account-1',
      creditLimit: Money.fromDouble(50000),
      cardKind: 'physical',
      cardNetwork: 'Mastercard',
      statementDay: 5,
      paymentDueDay: 30,
    );

    expect(profile.creditLimit.toDouble(), 50000);
    expect(profile.cardKind, 'physical');
    expect(profile.cardNetwork, 'Mastercard');
    expect(profile.statementDay, 5);
    expect(profile.paymentDueDay, 30);
  });
}

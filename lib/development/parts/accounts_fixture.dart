import '../../../services/account_service.dart';
import '../development_data.dart';
import 'package:flutter/foundation.dart';

class AccountsFixture {
  const AccountsFixture._();

  static Future<void> seed(AccountService accountService) async {
    debugPrint('Creating demo accounts...');
    await accountService.clearAllAccounts();

    await accountService.createSystemAccount(
      id: DevelopmentData.cashAccountId,
      name: 'Cash',
      type: 'cash',
      currency: 'EGP',
    );

    await accountService.createSystemAccount(
      id: DevelopmentData.bankAccountId,
      name: 'Bank',
      type: 'bank',
      currency: 'EGP',
    );

    await accountService.createSystemAccount(
      id: DevelopmentData.creditCardAccountId,
      name: 'Credit Card',
      type: 'creditCard',
      currency: 'EGP',
    );

    await accountService.createSystemAccount(
      id: DevelopmentData.savingsAccountId,
      name: 'Savings',
      type: 'realSaving',
      currency: 'EGP',
    );
    debugPrint('Accounts created successfully');
  }
}

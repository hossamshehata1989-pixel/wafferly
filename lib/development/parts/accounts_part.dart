import '../../../services/account_service.dart';
import '../development_data.dart';

class AccountsFixture {
  const AccountsFixture._();

  static Future<void> seed(AccountService accountService) async {
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
  }
}

import 'package:wafferly/application/accounts/account_application_service.dart';
import 'package:wafferly/application/accounts/account_transaction_service.dart';
import 'package:wafferly/services/account_service.dart';

class AccountBootstrap {
  const AccountBootstrap._();

  static AccountApplicationService create() {
    return AccountApplicationService(
      accountService: AccountService(),
      transactionService: const AccountTransactionService(),
    );
  }
}

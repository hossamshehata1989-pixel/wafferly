import 'package:wafferly/application/accounts/account_transaction_service.dart';
import 'package:wafferly/application/accounts/requests/update_account_request.dart';
import 'package:wafferly/services/account_service.dart';

class UpdateAccountUseCase {
  final AccountService _accountService;
  final AccountTransactionService _transactionService;

  const UpdateAccountUseCase({
    required AccountService accountService,
    required AccountTransactionService transactionService,
  }) : _accountService = accountService,
       _transactionService = transactionService;

  Future<void> execute(UpdateAccountRequest request) async {
    // Account edit is metadata/configuration only. Financial balance changes
    // must use the dedicated Balance Reconciliation operation.
    await _accountService.updateAccount(request.account);
  }
}

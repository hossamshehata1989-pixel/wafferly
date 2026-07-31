import 'package:wafferly/application/accounts/account_transaction_service.dart';
import 'package:wafferly/application/accounts/requests/create_account_request.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/services/account_service.dart';

class CreateAccountUseCase {
  final AccountService _accountService;
  final AccountTransactionService _transactionService;

  const CreateAccountUseCase({
    required AccountService accountService,
    required AccountTransactionService transactionService,
  }) : _accountService = accountService,
       _transactionService = transactionService;

  Future<Account> execute(CreateAccountRequest request) async {
    final account = await _accountService.createAccount(
      name: request.name,
      type: request.type,
      currency: request.currency,
      icon: request.icon,
      notes: request.notes,
    );

    await _transactionService.createInitialBalance(
      account: account,
      balance: request.balance,
      sectionType: request.sectionType,
      paymentMethod: request.type,
      currency: request.currency,
    );

    return account;
  }
}

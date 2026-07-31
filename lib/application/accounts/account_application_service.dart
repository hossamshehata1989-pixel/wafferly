import 'package:wafferly/models/account.dart';
import 'package:wafferly/services/account_service.dart';
import 'package:wafferly/application/accounts/requests/create_account_request.dart';
import 'package:wafferly/application/accounts/requests/update_account_request.dart';
import 'package:wafferly/application/accounts/account_transaction_service.dart';
import 'package:wafferly/application/accounts/use_cases/create_account_use_case.dart';
import 'package:wafferly/application/accounts/use_cases/update_account_use_case.dart';

class AccountApplicationService {
  final CreateAccountUseCase _createAccountUseCase;
  final UpdateAccountUseCase _updateAccountUseCase;

  AccountApplicationService({
    required AccountService accountService,
    required AccountTransactionService transactionService,
  }) : _createAccountUseCase = CreateAccountUseCase(
         accountService: accountService,
         transactionService: transactionService,
       ),
       _updateAccountUseCase = UpdateAccountUseCase(
         accountService: accountService,
         transactionService: transactionService,
       );

  Future<Account> createAccount(CreateAccountRequest request) {
    return _createAccountUseCase.execute(request);
  }

  Future<void> updateAccount(UpdateAccountRequest request) {
    return _updateAccountUseCase.execute(request);
  }
}

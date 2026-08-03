import 'package:hive_flutter/hive_flutter.dart';
import 'package:wafferly/application/accounts/account_application_service.dart';
import 'package:wafferly/application/accounts/account_transaction_service.dart';
import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/account_service.dart';
import 'package:wafferly/services/balance_service.dart';

class AccountBootstrap {
  const AccountBootstrap._();

  static AccountApplicationService create() {
    final engineContext = FinancialEngineBootstrap.create(
      balanceService: BalanceService(),
      transactionBox: Hive.box<Transaction>('transactions'),
    );

    return AccountApplicationService(
      accountService: AccountService(),
      transactionService: AccountTransactionService(
        engine: engineContext.engine,
      ),
    );
  }
}

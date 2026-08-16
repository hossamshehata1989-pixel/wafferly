
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../models/account.dart';
import '../../../../models/transaction.dart';
import '../../../../services/account_service.dart';
import '../../../../services/balance_service.dart';
import '../../../../core/planning/services/available_balance_projection_service.dart';
import '../../../../services/financial_action_engine.dart';

import '../account_details_models.dart';
import 'account_details_repository.dart';

class HiveAccountDetailsRepository implements AccountDetailsRepository {
  HiveAccountDetailsRepository({
    required this.projectionService,
    required this.actionEngine,
  });

  final AvailableBalanceProjectionService projectionService;
  final FinancialActionEngine actionEngine;

  Box<Transaction> get _transactions =>
      Hive.box<Transaction>('transactions');

  final BalanceService _balanceService = BalanceService();

  @override
  Account? getAccount(String accountId) {
    return AccountService().getAccountById(accountId);
  }

  @override
  double getBalance(String accountId) {
    return _balanceService.getBalance(accountId);
  }

  @override
  double getBalanceAtDate(String accountId, DateTime date) {
    return _balanceService.getBalanceAtDate(accountId, date);
  }

  @override
  Future<AccountProjection> getProjection({
    required String accountId,
    required double balance,
  }) async {
    final projection = await projectionService.project(
      accountId: accountId,
      balance: balance,
    );

    return AccountProjection(
      balance: projection.balance,
      available: projection.available,
      reserved: projection.reserved,
    );
  }

  @override
  List<Transaction> getTransactions(String accountId) {
    return _transactions.values.where((tx) {
      return tx.fromAccountId == accountId ||
          tx.toAccountId == accountId;
    }).toList();
  }

  @override
  Future<List<RecurringAccountItem>> getRecurring(
    String accountId,
  ) async {
    final contexts = await actionEngine.getActions(
      today: DateTime.now(),
    );

    return contexts
        .where(
          (context) =>
              context.action.sourceAccountId == accountId ||
              context.action.destinationAccountId == accountId,
        )
        .map(
          (context) {
            final action = context.action;
            final isIncome =
                action.destinationAccountId == accountId &&
                action.sourceAccountId != accountId;

            return RecurringAccountItem(
              id: action.id,
              title: action.title,
              subtitle: action.subtitle,
              amount: action.amount,
              currency: getAccount(accountId)?.currency ?? 'EGP',
              nextOccurrence: action.dueDate,
              isIncome: isIncome,
            );
          },
        )
        .toList();
  }
}

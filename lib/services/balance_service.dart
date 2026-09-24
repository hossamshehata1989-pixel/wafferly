import 'package:hive/hive.dart';

import '../models/transaction.dart';
import '../models/account.dart';
import '../models/enums/account_enums.dart';
import '../constants/transaction_constants.dart';
import '../core/planning/services/available_balance_projection_service.dart';
import 'financial_effective_transaction_query.dart';

class BalanceService {
  final Box<Transaction> txBox = Hive.box<Transaction>('transactions');

  final AvailableBalanceProjectionService? _availableBalanceProjectionService;
  final FinancialEffectiveTransactionQuery _effectiveQuery;

  BalanceService({
    AvailableBalanceProjectionService? availableBalanceProjectionService,
  }) : _availableBalanceProjectionService = availableBalanceProjectionService,
       _effectiveQuery = const FinancialEffectiveTransactionQuery();

  bool _isLiability(String accountId) {
    if (!Hive.isBoxOpen('accounts')) return false;
    final account = Hive.box<Account>('accounts').get(accountId);
    return account?.nature == AccountNature.liability;
  }

  double getBalance(String accountId) {
    double balance = 0;

    for (final tx in _effectiveQuery.getEffectiveTransactions()) {

      if (tx.type == TransactionType.initialBalance) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }

        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.transfer) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }

        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.expense) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.income) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.balanceReconciliation) {
        final isLiability = _isLiability(accountId);

        // BalanceReconciliation follows the same double-entry convention
        // as the ledger projection: `toAccountId` is the debit side and
        // `fromAccountId` is the credit side. Assets have a normal debit
        // balance; liabilities are represented as signed negative balances,
        // so the effect is reversed for liability accounts.
        if (tx.toAccountId == accountId) {
          balance += isLiability ? tx.amount : tx.amount;
        }

        if (tx.fromAccountId == accountId) {
          balance += isLiability ? -tx.amount : -tx.amount;
        }

        continue;
      }
    }

    return balance;
  }

  double getBalanceAtDate(String accountId, DateTime date) {
    double balance = 0;

    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    for (final tx in _effectiveQuery.getEffectiveTransactions()) {

      if (tx.date.isAfter(endOfDay)) {
        continue;
      }

      if (tx.type == TransactionType.initialBalance) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }

        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.transfer) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }

        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.expense) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.income) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }

        continue;
      }

      if (tx.type == TransactionType.balanceReconciliation) {
        final isLiability = _isLiability(accountId);

        // BalanceReconciliation follows the same double-entry convention
        // as the ledger projection: `toAccountId` is the debit side and
        // `fromAccountId` is the credit side. Assets have a normal debit
        // balance; liabilities are represented as signed negative balances,
        // so the effect is reversed for liability accounts.
        if (tx.toAccountId == accountId) {
          balance += isLiability ? tx.amount : tx.amount;
        }

        if (tx.fromAccountId == accountId) {
          balance += isLiability ? -tx.amount : -tx.amount;
        }

        continue;
      }
    }

    return balance;
  }

  /// Legacy available-balance path.
  ///
  /// Kept temporarily while existing synchronous callers
  /// are migrated to the Planning-based read path.
  double getAvailableBalance(String accountId) {
    throw StateError(
      'Legacy getAvailableBalance() is still being migrated '
      'to the Planning Allocation read path.',
    );
  }

  /// Planning-based available balance.
  ///
  /// Account Balance comes from the financial truth.
  /// Reserved Money comes from active Planning Allocations.
  Future<double> getAvailableBalanceFromPlanning(String accountId) async {
    final projectionService = _availableBalanceProjectionService;

    if (projectionService == null) {
      throw StateError(
        'AvailableBalanceProjectionService is required '
        'for Planning-based available balance.',
      );
    }

    final balance = getBalance(accountId);

    final projection = await projectionService.project(
      accountId: accountId,
      balance: balance,
    );

    return projection.available.toDouble();
  }
}

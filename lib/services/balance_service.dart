import 'package:hive/hive.dart';

import '../models/transaction.dart';
import '../constants/transaction_constants.dart';
import '../core/planning/services/available_balance_projection_service.dart';

class BalanceService {
  final Box<Transaction> txBox = Hive.box<Transaction>('transactions');

  final AvailableBalanceProjectionService? _availableBalanceProjectionService;

  BalanceService({
    AvailableBalanceProjectionService? availableBalanceProjectionService,
  }) : _availableBalanceProjectionService = availableBalanceProjectionService;

  double getBalance(String accountId) {
    double balance = 0;

    for (final tx in txBox.values) {
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
    }

    return balance;
  }

  double getBalanceAtDate(String accountId, DateTime date) {
    double balance = 0;

    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    for (final tx in txBox.values) {
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

    return projection.available;
  }
}


import 'package:hive_flutter/hive_flutter.dart';

import '../../../constants/transaction_constants.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';

import 'account_details_models.dart';
import 'data/account_details_repository.dart';

class AccountDetailsLogic {
  const AccountDetailsLogic._();

  static Future<AccountDetailsData> load({
    required AccountDetailsRepository repository,
    required String accountId,
  }) async {
    final account = repository.getAccount(accountId);
    if (account == null) {
      throw StateError('Account "$accountId" was not found.');
    }

    final balance = repository.getBalance(accountId);
    final projection = await repository.getProjection(
      accountId: accountId,
      balance: balance,
    );

    final transactions = repository
        .getTransactions(accountId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    double monthIn = 0;
    double monthOut = 0;

    for (final tx in transactions) {
      if (tx.date.isBefore(monthStart)) continue;

      if (_isIncomeForAccount(tx, accountId)) {
        monthIn += tx.amount;
      } else if (_isExpenseForAccount(tx, accountId)) {
        monthOut += tx.amount;
      }
    }

    final activity = transactions.take(30).map((tx) {
      final isIncome = _isIncomeForAccount(tx, accountId);
      return AccountActivityItem(
        id: tx.id,
        title: _transactionTitle(tx),
        category: tx.categoryId ?? 'Transaction',
        amount: tx.amount,
        date: tx.date,
        isIncome: isIncome,
      );
    }).toList();

    final chart = _buildBalanceChart(
      repository: repository,
      accountId: accountId,
      transactions: transactions,
      balance: balance,
      now: now,
    );

    final health = _buildHealth(
      balance: balance,
      available: projection.available,
      reserved: projection.reserved,
      monthIn: monthIn,
      monthOut: monthOut,
    );

    return AccountDetailsData(
      account: account,
      balance: balance,
      available: projection.available,
      reserved: projection.reserved,
      monthIn: monthIn,
      monthOut: monthOut,
      chart: chart,
      activity: activity,
      recurring: await repository.getRecurring(accountId),
      health: health,
    );
  }


  static List<BalancePoint> _buildBalanceChart({
    required AccountDetailsRepository repository,
    required String accountId,
    required List<Transaction> transactions,
    required double balance,
    required DateTime now,
  }) {
    // Opening Balance establishes the starting position; it is not a movement
    // for chart purposes.
    final realTransactions = transactions
        .where((tx) => tx.type != TransactionType.initialBalance)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (realTransactions.isEmpty) return const <BalancePoint>[];

    final firstDay = DateTime(
      realTransactions.first.date.year,
      realTransactions.first.date.month,
      realTransactions.first.date.day,
    );

    final allSameDay = realTransactions.every(
      (tx) =>
          tx.date.year == firstDay.year &&
          tx.date.month == firstDay.month &&
          tx.date.day == firstDay.day,
    );

    if (allSameDay) {
      // When all real movements happen on one day, six monthly snapshots
      // collapse the movement into an unreadable spike. Build a transaction
      // sequence instead: starting balance -> each real movement -> final.
      double startingBalance = balance;
      for (final tx in realTransactions) {
        startingBalance -= _netEffectForAccount(tx, accountId);
      }

      final points = <BalancePoint>[
        BalancePoint(date: firstDay, value: startingBalance),
      ];

      var runningBalance = startingBalance;
      for (final tx in realTransactions) {
        runningBalance += _netEffectForAccount(tx, accountId);
        points.add(
          BalancePoint(date: tx.date, value: runningBalance),
        );
      }

      return points;
    }

    final points = <BalancePoint>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i + 1, 0);
      points.add(
        BalancePoint(
          date: date,
          value: repository.getBalanceAtDate(accountId, date),
        ),
      );
    }
    return points;
  }

  static double _netEffectForAccount(Transaction tx, String accountId) {
    if (tx.type == TransactionType.income) {
      return tx.toAccountId == accountId ? tx.amount : 0;
    }

    if (tx.type == TransactionType.expense) {
      return tx.fromAccountId == accountId ? -tx.amount : 0;
    }

    if (tx.type == TransactionType.transfer) {
      if (tx.toAccountId == accountId && tx.fromAccountId != accountId) {
        return tx.amount;
      }
      if (tx.fromAccountId == accountId && tx.toAccountId != accountId) {
        return -tx.amount;
      }
    }

    return 0;
  }

  static bool _isIncomeForAccount(Transaction tx, String accountId) {
    if (tx.type == TransactionType.income) {
      return tx.toAccountId == accountId;
    }

    if (tx.type == TransactionType.transfer) {
      return tx.toAccountId == accountId;
    }

    if (tx.type == TransactionType.initialBalance) {
      return tx.toAccountId == accountId;
    }

    return false;
  }

  static bool _isExpenseForAccount(Transaction tx, String accountId) {
    if (tx.type == TransactionType.expense) {
      return tx.fromAccountId == accountId;
    }

    if (tx.type == TransactionType.transfer) {
      return tx.fromAccountId == accountId;
    }

    if (tx.type == TransactionType.initialBalance) {
      return tx.fromAccountId == accountId;
    }

    return false;
  }

  static String _transactionTitle(Transaction tx) {
    final note = tx.note?.trim();
    if (note != null && note.isNotEmpty) return note;

    switch (tx.type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.initialBalance:
        return 'Opening Balance';
      default:
        return 'Transaction';
    }
  }

  static AccountHealthData _buildHealth({
    required double balance,
    required double available,
    required double reserved,
    required double monthIn,
    required double monthOut,
  }) {
    int score = 60;
    final points = <String>[];

    if (balance > 0) {
      score += 15;
      points.add('Positive account balance');
    }

    if (available > 0) {
      score += 15;
      points.add('Good available balance');
    }

    if (reserved <= balance.abs() * .5 || balance == 0) {
      score += 10;
      points.add('Low commitment ratio');
    }

    if (monthIn >= monthOut) {
      points.add('Positive monthly cash flow');
    }

    score = score.clamp(0, 100).toInt();

    final label = score >= 80
        ? 'Healthy'
        : score >= 60
            ? 'Stable'
            : 'Needs attention';

    if (points.isEmpty) {
      points.add('Not enough financial activity for a stronger signal');
    }

    return AccountHealthData(
      score: score,
      label: label,
      points: points.take(3).toList(),
    );
  }
}

// lib/services/balance_service.dart

import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../constants/transaction_constants.dart';
import 'reserved_money_service.dart';

class BalanceService {
  final Box<Transaction> txBox = Hive.box<Transaction>('transactions');
  final ReservedMoneyService _reservedService = ReservedMoneyService();

  double getBalance(String accountId) {
    double balance = 0;

    for (final tx in txBox.values) {
      // 🟦 INITIAL BALANCE
      if (tx.type == TransactionType.initialBalance) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
        continue;
      }

      // 🟨 TRANSFER
      if (tx.type == TransactionType.transfer) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
        continue;
      }

      // 🟥 EXPENSE
      if (tx.type == TransactionType.expense) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }
        continue;
      }

      // 🟩 INCOME
      if (tx.type == TransactionType.income) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
        continue;
      }
    }

    return balance;
  }

  /// حساب الرصيد في تاريخ محدد
  double getBalanceAtDate(String accountId, DateTime date) {
    double balance = 0;

    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    for (final tx in txBox.values) {
      if (tx.date.isAfter(endOfDay)) {
        continue;
      }

      // 🟦 INITIAL BALANCE
      if (tx.type == TransactionType.initialBalance) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
        continue;
      }

      // 🟨 TRANSFER
      if (tx.type == TransactionType.transfer) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
        continue;
      }

      // 🟥 EXPENSE
      if (tx.type == TransactionType.expense) {
        if (tx.fromAccountId == accountId) {
          balance -= tx.amount;
        }
        continue;
      }

      // 🟩 INCOME
      if (tx.type == TransactionType.income) {
        if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
        continue;
      }
    }

    return balance;
  }

  /// حساب الرصيد المتاح (الرصيد الحقيقي - المبلغ المحجوز)
  double getAvailableBalance(String accountId) {
    final realBalance = getBalance(accountId);
    final reservedAmount = _reservedService.getReservedAmount(accountId);
    return realBalance - reservedAmount;
  }
}

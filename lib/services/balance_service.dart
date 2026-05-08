// lib/services/balance_service.dart

import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../constants/transaction_constants.dart';

class BalanceService {

  final Box<Transaction> txBox = Hive.box<Transaction>('transactions');

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
}
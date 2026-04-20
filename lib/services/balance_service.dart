// lib/services/balance_service.dart
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class BalanceService {
  final Box<Transaction> box = Hive.box<Transaction>('transactions');

  double getBalance(String accountId) {
    double balance = 0;

    for (final tx in box.values) {
      // 🟥 خرج فلوس
      if (tx.fromAccountId == accountId) {
        balance -= tx.amount;
        print("💰 [$accountId] OUT: -${tx.amount} = $balance");
      }

      // 🟩 دخل فلوس
      if (tx.toAccountId == accountId) {
        balance += tx.amount;
        print("💰 [$accountId] IN: +${tx.amount} = $balance");
      }
    }

    print("💰 [$accountId] FINAL BALANCE: $balance");
    return balance;
  }
}
import '../models/transaction.dart';

double calculateAccountBalance(
  String accountId,
  List<Transaction> transactions,
) {
  double balance = 0;

  for (final t in transactions) {
    if (t.fromAccountId == accountId) {
      balance -= t.amount;
    }

    if (t.toAccountId == accountId) {
      balance += t.amount;
    }
  }

  return balance;
}
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/section_type.dart';
import 'package:wafferly/models/transaction.dart';

class AccountTransactionService {
  const AccountTransactionService();

  Future<void> createInitialBalance({
    required Account account,
    required double balance,
    required SectionType sectionType,
    required String paymentMethod,
    required String currency,
  }) async {
    if (balance == 0) return;

    final isLiability = sectionType == SectionType.liabilities;
    final initialBalanceAmount = isLiability ? -balance : balance;

    final transaction = Transaction.create(
      amount: initialBalanceAmount.abs(),
      type: TransactionType.initialBalance,
      fromAccountId: initialBalanceAmount < 0 ? account.id : null,
      toAccountId: initialBalanceAmount > 0 ? account.id : null,
      categoryId: "initial_balance",
      date: DateTime.now(),
      note: "Initial balance",
      isExceptional: false,
      paymentMethod: paymentMethod,
      currencyCode: currency,
      source: TransactionSource.accountCreation,
    );

    await Hive.box<Transaction>(
      'transactions',
    ).put(transaction.id, transaction);
  }

  Future<void> createBalanceAdjustment({
    required String accountId,
    required double oldBalance,
    required double newBalance,
    required String paymentMethod,
    required String currency,
  }) async {
    final difference = newBalance - oldBalance;

    if (difference == 0) return;

    final transaction = Transaction.create(
      amount: difference.abs(),
      type: TransactionType.balanceAdjustment,
      fromAccountId: difference < 0 ? accountId : null,
      toAccountId: difference > 0 ? accountId : null,
      categoryId: "balance_adjustment",
      date: DateTime.now(),
      note: "Manual balance adjustment",
      isExceptional: false,
      paymentMethod: paymentMethod,
      currencyCode: currency,
      source: TransactionSource.balanceAdjustment,
    );

    await Hive.box<Transaction>(
      'transactions',
    ).put(transaction.id, transaction);
  }
}

// lib/services/transaction_query_service.dart
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/transaction_constants.dart';
import '../models/transaction.dart';
import 'financial_effective_transaction_query.dart';

/// Application read API for effective financial transactions.
///
/// This service is query-only. It never mutates the transaction store.
/// Effective financial truth is selected by [FinancialEffectiveTransactionQuery].
final class TransactionQueryService {
  const TransactionQueryService({
    FinancialEffectiveTransactionQuery effectiveQuery =
        const FinancialEffectiveTransactionQuery(),
  }) : _effectiveQuery = effectiveQuery;

  final FinancialEffectiveTransactionQuery _effectiveQuery;

  Box<Transaction>? get _box {
    if (!Hive.isBoxOpen('transactions')) return null;
    return Hive.box<Transaction>('transactions');
  }

  /// All effective transactions, newest first.
  List<Transaction> getAllTransactions() {
    final transactions = _effectiveQuery.getEffectiveTransactions();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Effective transaction by ID.
  Transaction? getById(String id) => _effectiveQuery.getEffectiveById(id);

  /// Effective transactions by type, newest first.
  List<Transaction> getByType(String type) {
    final transactions = _effectiveQuery
        .getEffectiveTransactions()
        .where((tx) => tx.type == type)
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  List<Transaction> getIncomeTransactions() {
    return getByType(TransactionType.income);
  }

  List<Transaction> getExpenseTransactions() {
    return getByType(TransactionType.expense);
  }

  List<Transaction> getByCategory(String categoryId) {
    final transactions = _effectiveQuery
        .getEffectiveTransactions()
        .where((tx) => tx.categoryId == categoryId)
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  List<Transaction> getByDateRange(DateTime start, DateTime end) {
    final transactions = _effectiveQuery
        .getEffectiveTransactions()
        .where((tx) {
          return tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
              tx.date.isBefore(end.add(const Duration(days: 1)));
        })
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  List<Transaction> getForAccount(String accountId) {
    final transactions = _effectiveQuery
        .getEffectiveTransactions()
        .where((tx) =>
            tx.fromAccountId == accountId || tx.toAccountId == accountId)
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  bool hasTransactionsForAccount(String accountId) {
    return _effectiveQuery.getEffectiveTransactions().any((tx) =>
        tx.fromAccountId == accountId || tx.toAccountId == accountId);
  }

  double getTotalByType(String type, DateTime start, DateTime end) {
    return getByDateRange(start, end)
        .where((tx) => tx.type == type)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getTotalExpenses(DateTime start, DateTime end) {
    return getTotalByType(TransactionType.expense, start, end);
  }

  double getTotalIncome(DateTime start, DateTime end) {
    return getTotalByType(TransactionType.income, start, end);
  }

  double getNormalExpenses(DateTime start, DateTime end) {
    return getByDateRange(start, end)
        .where((tx) => tx.type == TransactionType.expense && !tx.isExceptional)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getExceptionalExpenses(DateTime start, DateTime end) {
    return getByDateRange(start, end)
        .where((tx) => tx.type == TransactionType.expense && tx.isExceptional)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Map<String, double> getExpensesByCategory(DateTime start, DateTime end) {
    final result = <String, double>{};
    for (final tx in getByDateRange(start, end)) {
      if (tx.type == TransactionType.expense && tx.categoryId != null) {
        result[tx.categoryId!] = (result[tx.categoryId!] ?? 0) + tx.amount;
      }
    }
    return result;
  }

  Map<String, double> getExpensesBySource(DateTime start, DateTime end) {
    final result = <String, double>{};
    for (final tx in getByDateRange(start, end)) {
      if (tx.type == TransactionType.expense) {
        result[tx.source] = (result[tx.source] ?? 0) + tx.amount;
      }
    }
    return result;
  }

  /// Legacy transaction records retained for migration/diagnostics only.
  List<Transaction> getLegacyTransactions() {
    final box = _box;
    if (box == null) return <Transaction>[];

    final transactions = box.values.where((tx) => tx.isLegacy).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Total persisted transaction count, including inactive historical records.
  int get count => _box?.length ?? 0;

  bool get isEmpty => _box?.isEmpty ?? true;
  bool get isNotEmpty => _box?.isNotEmpty ?? false;
}

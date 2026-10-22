// lib/features/analysis/helpers/analysis_helpers.dart

import '../../../models/transaction.dart';
import '../../../constants/transaction_constants.dart';
import '../../../core/money/money.dart';

/// ==========================================
/// 📊 GROUPING
/// ==========================================

/// Group transactions by main category (categoryId)
/// categoryId is ALWAYS the main category - no fallback
Map<String, double> groupByMainCategory(List<Transaction> transactions) {
  // Exact accumulation; convert only at the existing chart/UI boundary.
  // Callers must first isolate transactions to one currency.
  final totals = <String, Money>{};
  for (final tx in transactions) {
    final categoryId = tx.categoryId;
    if (categoryId == null) continue;
    totals[categoryId] =
        (totals[categoryId] ?? Money.zero) + Money.fromDouble(tx.amount);
  }
  return totals.map((key, value) => MapEntry(key, value.toDouble()));
}

/// Group transactions by sub category within a specific main category
/// Uses subCategoryId directly - no fallback
/// Transactions with subCategoryId == null are ignored (user selected main category directly)
Map<String, double> groupBySubCategory(
  List<Transaction> transactions,
  String mainCategoryId,
) {
  final totals = <String, Money>{};
  for (final tx in transactions) {
    if (tx.categoryId != mainCategoryId) continue;
    final subId = tx.subCategoryId;
    if (subId != null) {
      totals[subId] =
          (totals[subId] ?? Money.zero) + Money.fromDouble(tx.amount);
    }
  }
  return totals.map((key, value) => MapEntry(key, value.toDouble()));
}

/// ==========================================
/// 🧹 FILTERING
/// ==========================================

/// Cash purchases and credit-card charges both represent spending.
/// Card payments are transfers and intentionally are not included here.
bool isSpendingTransaction(Transaction transaction) =>
    transaction.type == TransactionType.expense ||
    transaction.type == TransactionType.creditCardCharge;

List<Transaction> filterExpenses(List<Transaction> transactions) {
  return transactions.where(isSpendingTransaction).toList();
}

List<Transaction> filterRealExpenses(List<Transaction> transactions) {
  return transactions
      .where((t) => isSpendingTransaction(t) && !t.isExceptional)
      .toList();
}

List<Transaction> filterExceptionalExpenses(List<Transaction> transactions) {
  return transactions
      .where((t) => isSpendingTransaction(t) && t.isExceptional)
      .toList();
}

/// ==========================================
/// 🧮 CALCULATIONS
/// ==========================================

double sumAmounts(List<Transaction> transactions) {
  // Keep monetary addition decimal-exact; this legacy-facing helper returns
  // double because the existing chart widgets are double-based.
  return transactions.fold<Money>(
    Money.zero,
    (sum, tx) => sum + Money.fromDouble(tx.amount),
  ).toDouble();
}

/// Returns null when previous == 0 (ambiguous change)
/// UI layer decides how to handle this case
double? calculateChange(double current, double previous) {
  if (previous == 0) return null;
  return ((current - previous) / previous) * 100;
}

/// ==========================================
/// 📊 SORTING
/// ==========================================

List<MapEntry<String, double>> sortCategoriesDescending(
  Map<String, double> categories,
) {
  final entries = categories.entries.toList();
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

// lib/features/analysis/helpers/analysis_helpers.dart

import '../../../models/transaction.dart';
import '../../../constants/transaction_constants.dart';

/// ==========================================
/// 📊 GROUPING
/// ==========================================

/// Group transactions by main category (categoryId)
/// categoryId is ALWAYS the main category - no fallback
Map<String, double> groupByMainCategory(List<Transaction> transactions) {
  final result = <String, double>{};

  for (final tx in transactions) {
    if (tx.categoryId == null) continue;

    result[tx.categoryId!] = (result[tx.categoryId!] ?? 0) + tx.amount;
  }

  return result;
}

/// Group transactions by sub category within a specific main category
/// Uses subCategoryId directly - no fallback
/// Transactions with subCategoryId == null are ignored (user selected main category directly)
Map<String, double> groupBySubCategory(
  List<Transaction> transactions,
  String mainCategoryId,
) {
  final result = <String, double>{};
  for (final tx in transactions) {
    if (tx.categoryId == null) continue;
    if (tx.categoryId != mainCategoryId) continue;
    final subId = tx.subCategoryId;
    if (subId != null) {
      result[subId] = (result[subId] ?? 0) + tx.amount;
    }
  }
  return result;
}

/// ==========================================
/// 🧹 FILTERING
/// ==========================================

List<Transaction> filterExpenses(List<Transaction> transactions) {
  return transactions.where((t) => t.type == TransactionType.expense).toList();
}

List<Transaction> filterRealExpenses(List<Transaction> transactions) {
  return transactions
      .where((t) => t.type == TransactionType.expense && !t.isExceptional)
      .toList();
}

List<Transaction> filterExceptionalExpenses(List<Transaction> transactions) {
  return transactions
      .where((t) => t.type == TransactionType.expense && t.isExceptional)
      .toList();
}

/// ==========================================
/// 🧮 CALCULATIONS
/// ==========================================

double sumAmounts(List<Transaction> transactions) {
  return transactions.fold(0.0, (sum, t) => sum + t.amount);
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

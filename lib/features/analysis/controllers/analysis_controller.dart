// lib/features/analysis/controllers/analysis_controller.dart

import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../../services/transaction_service.dart';
import '../../../l10n/app_localizations.dart';
import '../helpers/analysis_helpers.dart';
import '../registry/category_registry.dart';
import '../widgets/custom_donut_chart.dart';

class AnalysisController {
  final TransactionService _transactionService = TransactionService.instance;

  // State
  bool isLoading = true;
  String? error;

  // Total tab data
  List<Transaction> totalExpenses = [];
  double totalAmount = 0;
  double? totalChange;
  Map<String, double> totalByCategory = {};
  List<DonutData> totalDonutData = [];

  // Real tab data
  List<Transaction> realExpenses = [];
  double realAmount = 0;
  double? realChange;
  Map<String, double> realByCategory = {};
  List<DonutData> realDonutData = [];

  // Exceptional tab data
  List<Transaction> exceptionalExpenses = [];
  double exceptionalAmount = 0;
  double? exceptionalChange;
  Map<String, double> exceptionalByCategory = {};
  List<DonutData> exceptionalDonutData = [];

  // Simple callback for UI updates
  final VoidCallback onUpdate;

  AnalysisController({required this.onUpdate});

  Future<void> loadData({
    required DateTime startDate,
    required DateTime endDate,
    required DateTime previousStartDate,
    required DateTime previousEndDate,
    required AppLocalizations t,
  }) async {
    isLoading = true;
    onUpdate();

    try {
      final transactions = _transactionService.getByDateRange(
        startDate,
        endDate,
      );

      // Total expenses
      totalExpenses = filterExpenses(transactions);
      totalAmount = sumAmounts(totalExpenses);
      totalByCategory = groupByMainCategory(totalExpenses);
      totalDonutData = _buildDonutData(totalByCategory, t);

      // Real expenses
      realExpenses = filterRealExpenses(transactions);
      realAmount = sumAmounts(realExpenses);
      realByCategory = groupByMainCategory(realExpenses);
      realDonutData = _buildDonutData(realByCategory, t);

      // Exceptional expenses
      exceptionalExpenses = filterExceptionalExpenses(transactions);
      exceptionalAmount = sumAmounts(exceptionalExpenses);
      exceptionalByCategory = groupByMainCategory(exceptionalExpenses);
      exceptionalDonutData = _buildDonutData(exceptionalByCategory, t);

      // Calculate changes
      final prevTransactions = _transactionService.getByDateRange(
        previousStartDate,
        previousEndDate,
      );
      final prevTotal = sumAmounts(filterExpenses(prevTransactions));
      final prevReal = sumAmounts(filterRealExpenses(prevTransactions));
      final prevExceptional = sumAmounts(
        filterExceptionalExpenses(prevTransactions),
      );

      totalChange = calculateChange(totalAmount, prevTotal);
      realChange = calculateChange(realAmount, prevReal);
      exceptionalChange = calculateChange(exceptionalAmount, prevExceptional);

      error = null;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    onUpdate();
  }

  void dispose() {
    // Reserved for future cleanup
  }

  List<DonutData> _buildDonutData(
    Map<String, double> categories,
    AppLocalizations t,
  ) {
    final sortedEntries = sortCategoriesDescending(categories);
    return sortedEntries.map((entry) {
      final name = CategoryRegistry.getMainCategoryName(entry.key, t);
      return DonutData(name, entry.value);
    }).toList();
  }
}

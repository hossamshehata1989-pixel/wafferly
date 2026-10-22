// lib/features/analysis/controllers/analysis_controller.dart

import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../../services/transaction_query_service.dart';
import '../../../l10n/app_localizations.dart';
import '../helpers/analysis_helpers.dart';
import '../registry/category_registry.dart';
import '../widgets/custom_donut_chart.dart';

class AnalysisController {
  AnalysisController({
    required this.onUpdate,
    required TransactionQueryService transactionQueryService,
  }) : _transactionQueryService = transactionQueryService;

  final TransactionQueryService _transactionQueryService;

  /// Transactions carry currency but this version has no common/base amount.
  /// Report one currency at a time instead of adding unlike currencies.
  String selectedCurrencyCode = 'EGP';
  List<String> availableCurrencyCodes = <String>['EGP'];

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

  void selectCurrency(String currencyCode) {
    selectedCurrencyCode = _normalizeCurrencyCode(currencyCode);
  }

  String _normalizeCurrencyCode(String code) {
    final normalized = code.trim().toUpperCase();
    return normalized.isEmpty ? 'EGP' : normalized;
  }

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
      // Purchase analytics reports authoritative purchase rows on their
      // original dates. Statement/installment projections are separate views
      // for due-cycle/commitment reporting and must not be merged here.
      final currentRange =
          _transactionQueryService.getByDateRange(startDate, endDate);
      final previousRange = _transactionQueryService.getByDateRange(
        previousStartDate,
        previousEndDate,
      );

      final currencies = <String>{
        for (final tx in <Transaction>[...currentRange, ...previousRange])
          if (isSpendingTransaction(tx)) _normalizeCurrencyCode(tx.currencyCode),
      }.toList()
        ..sort();
      availableCurrencyCodes = currencies.isEmpty ? <String>['EGP'] : currencies;
      if (!availableCurrencyCodes.contains(selectedCurrencyCode)) {
        selectedCurrencyCode = availableCurrencyCodes.contains('EGP')
            ? 'EGP'
            : availableCurrencyCodes.first;
      }

      final transactions = currentRange
          .where((tx) =>
              _normalizeCurrencyCode(tx.currencyCode) == selectedCurrencyCode)
          .toList(growable: false);

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
      final prevTransactions = previousRange
          .where((tx) =>
              _normalizeCurrencyCode(tx.currencyCode) == selectedCurrencyCode)
          .toList(growable: false);
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

// lib/features/analysis/screens/main_category_details_screen.dart

import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';
import '../helpers/analysis_helpers.dart';
import '../registry/category_registry.dart';
import '../widgets/custom_donut_chart.dart';
import '../widgets/sub_category_row.dart';

class MainCategoryDetailsScreen extends StatelessWidget {
  final String mainCategoryId;
  final List<Transaction> expenses;
  final DateTime startDate;
  final DateTime endDate;

  const MainCategoryDetailsScreen({
    super.key,
    required this.mainCategoryId,
    required this.expenses,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currencyCode = 'EGP';

    final categoryName = CategoryRegistry.getMainCategoryName(
      mainCategoryId,
      t,
    );
    final totalAmount = sumAmounts(expenses);
    final subCategories = groupBySubCategory(expenses, mainCategoryId);
    final sortedSubs = sortCategoriesDescending(subCategories);
    final donutData = _buildDonutData(sortedSubs, t);
    final hasSubCategories = subCategories.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(categoryName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCard(
              t: t,
              categoryName: categoryName,
              totalAmount: totalAmount,
              currencyCode: currencyCode,
            ),
            const SizedBox(height: 24),
            if (hasSubCategories) ...[
              _buildDonutChart(t: t, donutData: donutData),
              const SizedBox(height: 24),
              _buildSubCategoriesList(
                t: t,
                subs: sortedSubs,
                total: totalAmount,
                currencyCode: currencyCode,
              ),
            ] else
              _buildEmptyState(t: t, categoryName: categoryName),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required AppLocalizations t,
    required String categoryName,
    required double totalAmount,
    required String currencyCode,
  }) {
    final color = CategoryRegistry.getColor(mainCategoryId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // ✅ FIXED: t.totalOf(categoryName) instead of t.totalOf
          Text(
            t.totalOf(categoryName),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(totalAmount, currencyCode),
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart({
    required AppLocalizations t,
    required List<DonutData> donutData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            t.subCategoriesDetails,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CustomDonutChart(
            data: donutData,
            baseColor: CategoryRegistry.getColor(mainCategoryId),
            size: 180,
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesList({
    required AppLocalizations t,
    required List<MapEntry<String, double>> subs,
    required double total,
    required String currencyCode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            t.subCategoriesList,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...subs.map(
            (entry) => SubCategoryRow(
              subCategoryId: entry.key,
              amount: entry.value,
              total: total,
              currencyCode: currencyCode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required AppLocalizations t,
    required String categoryName,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          // ✅ FIXED: t.noSubCategoriesIn(categoryName) instead of t.noSubCategoriesIn
          t.noSubCategoriesIn(categoryName),
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  List<DonutData> _buildDonutData(
    List<MapEntry<String, double>> sortedSubs,
    AppLocalizations t,
  ) {
    return sortedSubs.map((entry) {
      final name = CategoryRegistry.getSubCategoryName(entry.key, t);
      return DonutData(name, entry.value);
    }).toList();
  }
}

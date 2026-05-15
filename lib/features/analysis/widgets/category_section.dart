// lib/features/analysis/widgets/category_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'categories_list.dart';
import 'custom_donut_chart.dart';
import '../../../l10n/app_localizations.dart';

/// Pure UI widget - displays complete category section with donut chart
/// Receives pre-processed data from parent (including donutData)
class CategorySection extends StatelessWidget {
  final Map<String, double> categories;
  final List<DonutData> donutData;
  final Color baseColor;
  final Function(String) onCategoryTap;

  const CategorySection({
    super.key,
    required this.categories,
    required this.donutData,
    required this.baseColor,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final total = categories.values.fold(0.0, (s, v) => s + v);
    final sortedEntries = _sortCategories(categories);

    if (categories.isEmpty) {
      return _buildEmptyState(t);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(t, total),
          const SizedBox(height: 24),
          if (donutData.isNotEmpty)
            Center(
              child: CustomDonutChart(
                data: donutData,
                baseColor: baseColor,
                size: 160,
              ),
            ),
          const SizedBox(height: 24),
          CategoriesList(
            categories: sortedEntries,
            total: total,
            onCategoryTap: onCategoryTap,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(t.noData, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t, double total) {
    final formatter = NumberFormat("#,###");
    final formattedTotal = "${formatter.format(total.toInt())} EGP";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t.categories,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${t.totalLabel} $formattedTotal',
          style: TextStyle(
            color: baseColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, double>> _sortCategories(
    Map<String, double> categories,
  ) {
    final entries = categories.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

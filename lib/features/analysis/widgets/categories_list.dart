// lib/features/analysis/widgets/categories_list.dart

import 'package:flutter/material.dart';
import 'category_detail_row.dart';

/// Pure UI widget - displays a list of categories
/// Receives pre-sorted data from parent
class CategoriesList extends StatelessWidget {
  final List<MapEntry<String, double>> categories;
  final double total;
  final Function(String) onCategoryTap;

  const CategoriesList({
    super.key,
    required this.categories,
    required this.total,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'لا توجد بيانات',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Column(
      children: categories.map((entry) {
        return CategoryDetailRow(
          categoryId: entry.key,
          amount: entry.value,
          total: total,
          onTap: () => onCategoryTap(entry.key),
        );
      }).toList(),
    );
  }
}

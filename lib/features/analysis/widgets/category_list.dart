// lib/features/analysis/widgets/category_list.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/category_helper.dart';
import '../../../l10n/app_localizations.dart';

class CategoryList extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final Color color;

  const CategoryList({
    super.key,
    required this.data,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");
    final t = AppLocalizations.of(context)!;

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((e) {
        final percent = total == 0 ? 0 : (e.value / total) * 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  "${percent.toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getMainCategoryName(e.key, t),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${formatter.format(e.value.toInt())} EGP",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

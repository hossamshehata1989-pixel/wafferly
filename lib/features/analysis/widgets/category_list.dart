// ==========================================
// 📊 CATEGORY LIST (FIXED RTL)
// ==========================================

import 'package:flutter/material.dart';
import '../logic/analysis_calculator.dart';

class CategoryList extends StatelessWidget {
  final Map<String, double> data;
  final double total;

  const CategoryList({
    super.key,
    required this.data,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final categories = getTopCategories(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((e) {
        final percent =
            total == 0 ? 0 : (e.value / total) * 100;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [

              /// ICON
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              /// NAME
              Expanded(
                child: Text(
                  e.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl, // 🔥 FIX
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),

              /// AMOUNT
              Text(
                "${e.value.toInt()} EGP",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 10),

              /// %
              Text(
                "${percent.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
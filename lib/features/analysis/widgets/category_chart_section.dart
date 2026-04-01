// lib/features/analysis/widgets/category_chart_section.dart
import 'package:flutter/material.dart';
import '../../../models/expense.dart';
import 'custom_donut_chart.dart';
import 'category_list.dart';

class CategoryChartSection extends StatelessWidget {
  final String title;
  final List<Expense> expenses;
  final IconData icon;
  final Color color;

  const CategoryChartSection({
    super.key,
    required this.title,
    required this.expenses,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // تجميع المصروفات حسب الفئة
    final Map<String, double> categoryMap = {};
    for (final expense in expenses) {
      categoryMap[expense.mainCategory] = 
          (categoryMap[expense.mainCategory] ?? 0) + expense.amount;
    }

    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "Total: ${total.toInt()} EGP",
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // ✅ رسم بياني + قائمة الفئات
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donut Chart
              CustomDonutChart(
                data: _prepareDonutData(categoryMap),
                baseColor: color,
                size: 120,
              ),
              const SizedBox(width: 16),
              // Category List
              Expanded(
                child: CategoryList(
                  data: categoryMap,
                  total: total,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DonutData> _prepareDonutData(Map<String, double> data) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.length <= 4) {
      return sorted.map((e) => DonutData(e.key, e.value)).toList();
    }

    final top4 = sorted.take(4).toList();
    final others = sorted.skip(4);
    final otherSum = others.fold(0.0, (sum, e) => sum + e.value);
    final result = [...top4, MapEntry("Other", otherSum)];
    
    return result.map((e) => DonutData(e.key, e.value)).toList();
  }
}
// lib/features/analysis/screens/sub_category_details_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/expense.dart';
import '../../../config/category_config.dart';
import '../../../utils/category_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SubCategoryDetailsScreen extends StatelessWidget {
  final String mainCategory;
  final DateTime startDate;
  final DateTime endDate;

  const SubCategoryDetailsScreen({
    super.key,
    required this.mainCategory,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Expense>('expenses');
    final expenses = box.values.where((e) =>
      e.mainCategory == mainCategory &&
      e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      e.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    // تجميع حسب الفئة الفرعية
    final Map<String, double> subCategories = {};
    for (final expense in expenses) {
      subCategories[expense.subCategory] = 
          (subCategories[expense.subCategory] ?? 0) + expense.amount;
    }

    final sorted = subCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          mainCategory,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: sorted.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset(
                            getCategoryIcon(entry.key),
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.category, size: 24, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getSubCategoryName(entry.key),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          "${entry.value.toInt()} EGP",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubCategoryName(String id) {
    // البحث عن اسم الفئة الفرعية من التكوين
    for (final category in mainCategories) {
      final sub = category.subCategories?.firstWhere(
        (s) => s.id == id,
        orElse: () => SubCategoryConfig(id: id, title: (_) => id),
      );
      if (sub != null && sub.id == id) {
        // نحتاج إلى AppLocalizations هنا، لكن مؤقتاً نرجع الـ id
        return id;
      }
    }
    return id;
  }
}
// lib/features/analysis/widgets/category_details_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/expense.dart';
import '../../../utils/category_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'custom_donut_chart.dart';

class CategoryDetailsSection extends StatelessWidget {
  final String title;
  final List<Expense> expenses;
  final Color color;
  final bool isCompact;
  final Function(String) onSubCategoryTap;

  const CategoryDetailsSection({
    super.key,
    required this.title,
    required this.expenses,
    required this.color,
    this.isCompact = false,
    required this.onSubCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");

    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "No data for $title",
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    // ✅ تجميع المصروفات حسب الفئة الرئيسية (mainCategory)
    final Map<String, double> categoryMap = {};
    for (final expense in expenses) {
      categoryMap[expense.mainCategory] = 
          (categoryMap[expense.mainCategory] ?? 0) + expense.amount;
    }

    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final sorted = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final donutData = _prepareDonutData(categoryMap);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ العنوان والإجمالي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Total: ${formatter.format(total.toInt())} EGP",
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // ✅ الدائرة في المنتصف
          Center(
            child: CustomDonutChart(
              data: donutData,
              baseColor: color,
              size: 160,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ✅ قائمة الفئات الرئيسية (بدون خطوط متعرجة)
          ...sorted.map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            final categoryColor = _getCategoryColor(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // ✅ نقطة ملونة بجانب الفئة
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ اسم الفئة والنسبة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${percentage.toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ المبلغ
                  Text(
                    "${formatter.format(entry.value.toInt())} EGP",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ زر التفاصيل (للفئات الفرعية لاحقاً)
                  GestureDetector(
                    onTap: () => onSubCategoryTap(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ✅ تجهيز بيانات الدائرة (الفئات الرئيسية فقط)
  List<DonutData> _prepareDonutData(Map<String, double> data) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFFFF6B6B), // أحمر
      const Color(0xFF4ECDC4), // فيروزي
      const Color(0xFFFFE66D), // أصفر
      const Color(0xFFA8E6CF), // أخضر فاتح
      const Color(0xFFFF8B94), // وردي
      const Color(0xFFAA96DA), // بنفسجي
    ];

    if (sorted.length <= 6) {
      return sorted.asMap().entries.map((entry) {
        return DonutData(
          entry.value.key,
          entry.value.value,
          customColor: colors[entry.key % colors.length],
        );
      }).toList();
    }

    final top5 = sorted.take(5).toList();
    final others = sorted.skip(5);
    final otherSum = others.fold(0.0, (sum, e) => sum + e.value);
    final result = [...top5, MapEntry("Other", otherSum)];
    
    return result.asMap().entries.map((entry) {
      return DonutData(
        entry.value.key,
        entry.value.value,
        customColor: colors[entry.key % colors.length],
      );
    }).toList();
  }

  String _getCategoryId(String categoryName) {
    final map = {
      'مواصلات يومية': 'dailyTransport',
      'فواتير': 'bills',
      'سوبر ماركت': 'supermarket',
      'أكل بره': 'fastFood',
      'لحوم وأسماك': 'meatFish',
      'خضروات': 'vegetables',
      'فاكهة': 'fruits',
      'تدخين': 'smoking',
      'صحة': 'health',
      'ترفيه': 'entertainment',
      'تعليم': 'education',
      'مركبات': 'vehicles',
      'المنزل': 'home',
      'عناية شخصية': 'personalCare',
      'موبايل وكمبيوتر': 'mobilePc',
      'التزامات مالية': 'financials',
      'خدمات حكومية': 'governServices',
      'هدايا ومناسبات': 'giftsOccasions',
      'هوايات': 'hobbies',
      'بيبي': 'baby',
      'ملابس': 'clothes',
      'أحذية': 'shoes',
    };
    return map[categoryName] ?? categoryName;
  }

  // ✅ لون لكل فئة رئيسية (ثابت)
  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'أكل بره':
      case 'سوبر ماركت':
      case 'طعام':
      case 'Food':
        return const Color(0xFFFF6B6B); // أحمر
      case 'مواصلات يومية':
      case 'Transport':
        return const Color(0xFF4ECDC4); // فيروزي
      case 'ملابس':
      case 'أحذية':
      case 'Shopping':
        return const Color(0xFFFFE66D); // أصفر
      case 'فواتير':
      case 'Bills':
        return const Color(0xFFAA96DA); // بنفسجي
      case 'صحة':
      case 'Health':
        return const Color(0xFFFF8B94); // وردي
      default:
        return const Color(0xFFA8E6CF); // أخضر فاتح
    }
  }
}
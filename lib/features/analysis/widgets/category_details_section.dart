// lib/features/analysis/widgets/category_details_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'custom_donut_chart.dart';
import '../../../utils/category_icons.dart';
import '../../../config/category_config.dart';

class CategoryDetailsSection extends StatelessWidget {
  final String title;
  final List<MainCategoryData> mainCategoriesData;
  final Color color;
  final Function(String, String) onSubCategoryTap;

  const CategoryDetailsSection({
    super.key,
    required this.title,
    required this.mainCategoriesData,
    required this.color,
    required this.onSubCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final formatter = NumberFormat("#,###");
    
    // ✅ ترتيب تنازلي (من الأكبر للأصغر)
    final sortedCategories = [...mainCategoriesData]..sort((a, b) => b.total.compareTo(a.total));
    
    final total = sortedCategories.fold(0.0, (sum, e) => sum + e.total);
    
    // ✅ استخدام البيانات المرتبة في الدائرة
    final donutData = sortedCategories.map((e) => DonutData(e.name, e.total)).toList();

    String formatCurrency(double amount) {
      if (isArabic) {
        return "${formatter.format(amount.toInt())} ج.م";
      } else {
        return "${formatter.format(amount.toInt())} EGP";
      }
    }

    if (sortedCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "لا توجد بيانات لـ $title",
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                "الإجمالي: ${formatCurrency(total)}",
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // ✅ الدائرة (بتستخدم البيانات المرتبة)
          if (donutData.isNotEmpty)
            Center(
              child: CustomDonutChart(
                data: donutData,
                baseColor: color,
                size: 160,
              ),
            ),
          
          const SizedBox(height: 24),
          
          // ✅ القائمة (بتستخدم البيانات المرتبة sortedCategories)
          ...sortedCategories.map((category) {
            final percentage = total > 0 ? (category.total / total) * 100 : 0.0;
            final categoryColor = _getCategoryColor(category.id);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // ✅ أيقونة الفئة
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SvgPicture.asset(
                      getCategoryIcon(category.id),
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category,
                        size: 20,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ اسم الفئة والنسبة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
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
                    formatCurrency(category.total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ زر التفاصيل
                  GestureDetector(
                    onTap: () => onSubCategoryTap(category.id, category.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "تفاصيل",
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

  Color _getCategoryColor(String categoryId) {
    final colors = {
      'dailyTransport': const Color(0xFF4ECDC4),
      'bills': const Color(0xFFAA96DA),
      'supermarket': const Color(0xFFFF6B6B),
      'fastFood': const Color(0xFFFF6B6B),
      'meatFish': const Color(0xFFFF6B6B),
      'vegetables': const Color(0xFFA8E6CF),
      'fruits': const Color(0xFFA8E6CF),
      'smoking': const Color(0xFFFF8B94),
      'health': const Color(0xFFFF8B94),
      'entertainment': const Color(0xFFFFE66D),
      'education': const Color(0xFFFFE66D),
      'vehicles': const Color(0xFF4ECDC4),
      'home': const Color(0xFFAA96DA),
      'personalCare': const Color(0xFFFF8B94),
      'mobilePc': const Color(0xFF4ECDC4),
      'financials': const Color(0xFFAA96DA),
      'governServices': const Color(0xFFAA96DA),
      'giftsOccasions': const Color(0xFFFFE66D),
      'hobbies': const Color(0xFFFFE66D),
      'baby': const Color(0xFFFF8B94),
      'clothes': const Color(0xFFFF6B6B),
      'shoes': const Color(0xFFFF6B6B),
    };
    return colors[categoryId] ?? const Color(0xFFA8E6CF);
  }
}

// ✅ كلاس MainCategoryData
class MainCategoryData {
  final String id;
  final String name;
  final double total;
  
  MainCategoryData({
    required this.id,
    required this.name,
    required this.total,
  });
}
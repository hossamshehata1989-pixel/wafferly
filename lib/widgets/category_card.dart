import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_icons.dart';
import 'add_expense_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CategoryCard extends StatelessWidget {
  final String categoryId;   // id المنطقي (transport, bills, ...)
  final String titleKey;     // key للترجمة (transport, bills, ...)
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CategoryCard({
    super.key,
    required this.categoryId,
    required this.titleKey,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AnimatedScale(
      scale: selected ? 1.05 : 1,     // تكبير الكارت المحدد
      duration: const Duration(milliseconds: 160),      // سرعة التحريك
      curve: Curves.easeOut,
      child: Material(          // تصميم الكارت
        color: selected ? Colors.yellow.withOpacity(0.35) : Colors.white,         // خلفية مميزة للكارت المحدد
        borderRadius: BorderRadius.circular(16),
        elevation: selected ? 100 : 10,            // ظل أقوى للكارت المحدد
         shadowColor: selected ? Colors.yellow.withOpacity(0.5) : Colors.black.withOpacity(0.1),         // لون ظل مميز للكارت المحدد
        child: InkWell(               // تفاعل اللمس
          borderRadius: BorderRadius.circular(16),           // تأثير الحواف الدائرية عند اللمس
          splashColor: Colors.blue.withOpacity(0.15),       // تأثير اللمس
          onTap: () {
            onTap();
            showAddExpenseSheet(
              context,
              _resolveTitle(t),
            );
          },
          onLongPress: onLongPress,          // تفاعل الضغط المطول
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? Colors.blue : Colors.black.withOpacity(0.12),
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(4), // المسافة بين الحافة والمحتوى

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// 🔷 الأيقونة
               SvgPicture.asset(
                getCategoryIcon(categoryId),
                  width: 30,
                 height: 30,
                ),

                const SizedBox(height: 8),        // المسافة بين الأيقونة والنص

                /// 🔷 اسم الفئة
                Text(
                  _resolveTitle(t),                // ترجمة العنوان بناءً على الـ titleKey
                  textAlign: TextAlign.center,         // محاذاة النص في الوسط
                  style: const TextStyle(                // 🔴 نمط النص
                    fontSize: 11,
                    fontWeight: FontWeight.bold,         // يمكنك تعديل النمط حسب التصميم الذي تريده
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// حل gen-l10n للـ dynamic key
  String _resolveTitle(AppLocalizations t) {
    switch (titleKey) {
      case 'transport': return t.transport;
      case 'bills': return t.bills;
      case 'supermarket': return t.supermarket;
      case 'eatOut': return t.eatOut;
      case 'meatFish': return t.meatFish;
      case 'vegetables': return t.vegetables;
      case 'fruits': return t.fruits;
      case 'smoking': return t.smoking;
      case 'health': return t.health;
      case 'entertainment': return t.entertainment;
      case 'education': return t.education;
      case 'vehicles': return t.vehicles;
      case 'home': return t.home;
      case 'personalCare': return t.personalCare;
      case 'mobilePc': return t.mobilePc;
      case 'financialCommitments': return t.financialCommitments;
      case 'governmentServices': return t.governmentServices;
      case 'giftsOccasions': return t.giftsOccasions;
      case 'hobbies': return t.hobbies;
      case 'baby': return t.baby;
      case 'clothes': return t.clothes;
      case 'shoes': return t.shoes;
      default:
        return titleKey; // fallback آمن
    }
  }
}

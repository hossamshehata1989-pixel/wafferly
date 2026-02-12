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
      scale: selected ? 1.05 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: Material(
        color: selected ? Colors.yellow.withOpacity(0.35) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: selected ? 100 : 10,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.blue.withOpacity(0.15),
          onTap: () {
            onTap();
            showAddExpenseSheet(
              context,
              _resolveTitle(t),
            );
          },
          onLongPress: onLongPress,
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
                  width: 50,
                 height: 50,
                ),

                const SizedBox(height: 8),

                /// 🔷 اسم الفئة
                Text(
                  _resolveTitle(t),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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

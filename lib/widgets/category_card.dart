import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_icons.dart';
import '../utils/translation_helper.dart';
import 'add_expense_bottom_sheet.dart';

class CategoryCard extends StatelessWidget {
  final String titleKey;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CategoryCard({
    super.key,
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
        color: selected
            ? Colors.yellow.withOpacity(0.35)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: selected ? 6 : 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.blue.withOpacity(0.15),
          onTap: () {
            onTap();
            showAddExpenseSheet(context, t.tr(titleKey));
          },
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Colors.blue
                    : Colors.black.withOpacity(0.12),
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// 🔷 الأيقونة في النص
                Icon(
                  getMainCategoryIcon(titleKey),
                  size: 40,
                  color: selected
                      ? Colors.blue
                      : Colors.black87,
                ),
                const SizedBox(height: 10),

                /// 🔷 اسم الفئة
                Text(
                  t.tr(titleKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
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
}

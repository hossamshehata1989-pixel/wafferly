import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_icons.dart';
import 'add_expense_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CategoryCard extends StatelessWidget {
  final String categoryId;
  final String Function(AppLocalizations) title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CategoryCard({
    super.key,
    required this.categoryId,
    required this.title,
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
        elevation: selected ? 10 : 4,
        shadowColor: selected
            ? Colors.yellow.withOpacity(0.5)
            : Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.blue.withOpacity(0.15),
          onTap: () {
            onTap();
            showAddExpenseSheet(
              context,
              title(t), // 🔥 النظام الجديد
            );
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
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                /// 🔷 Icon
                SvgPicture.asset(
                  getCategoryIcon(categoryId),
                  width: 25,
                  height: 25,
                ),

                const SizedBox(height: 8),

                /// 🔷 Title
                Text(
                  title(t), // 🔥 بدون switch
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
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
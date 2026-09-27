import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_icons.dart';
import 'add_expense_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CategoryCard extends StatelessWidget {
  final String categoryId;
  final String Function(AppLocalizations) title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueNotifier<SelectedCategory>? selectedCategory;

  const CategoryCard({
    super.key,
    required this.categoryId,
    required this.title,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AnimatedScale(
      scale: selected ? 1.05 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: Material(
        color: selected ? const Color(0xFF3A7BFF) : const Color(0xFF1B2A6B),
        borderRadius: BorderRadius.circular(8),
        elevation: selected ? 10 : 4,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: const Color(0xFF4FD1FF).withOpacity(.3),
          onTap: () {
            onTap();

            if (selectedCategory != null) {
              Future.microtask(() {
                showAddExpenseSheet(context, selectedCategory!);
              });
            }
          },
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? const Color(0xFF4FD1FF) : const Color(0xFF243A8F)),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  getCategoryIcon(categoryId),
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.category, size: 25, color: Colors.white),
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  title(t),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 8,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
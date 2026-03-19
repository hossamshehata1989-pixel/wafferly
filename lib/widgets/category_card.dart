import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/category_icons.dart';
import '../widgets/add_expense_bottom_sheet.dart';

class CategoryCard extends StatelessWidget {

  final String categoryId;
  final String Function(AppLocalizations) title;

  final bool selected;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  final ValueNotifier<SelectedCategory> selectedCategory;

  const CategoryCard({
    super.key,
    required this.categoryId,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.selectedCategory,
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
            ? AppColors.primary.withOpacity(0.35)
            : AppColors.card,

        borderRadius: BorderRadius.circular(16),

        elevation: selected ? 10 : 4,

        shadowColor: selected
            ? AppColors.primary.withOpacity(0.5)
            : Colors.black.withOpacity(0.1),

        child: InkWell(

          borderRadius: BorderRadius.circular(6),

          splashColor: AppColors.primary.withOpacity(0.15),

          onTap: () {

            /// تحديث الفئة المختارة
            selectedCategory.value = SelectedCategory(
              id: categoryId,
              name: title(t),
            );

            /// تحديث اختيار الكارت
            onTap();

            /// فتح BottomSheet
            showAddExpenseSheet(
              context,
              selectedCategory,
            );

          },

          onLongPress: onLongPress,

          child: Container(

            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(8),

              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.cardSecondary,
                width: 1,
              ),

            ),

            padding: const EdgeInsets.all(2),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                /// Icon
                SvgPicture.asset(
                  getCategoryIcon(categoryId),
                  width: 25,
                  height: 25,
                ),

                const SizedBox(height: 2),

                /// Title
                Text(

                  title(t),

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
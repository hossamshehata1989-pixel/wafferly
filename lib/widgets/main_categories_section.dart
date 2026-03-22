import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';

/// 🌍 Localization
import '../l10n/app_localizations.dart';

/// 📊 Data
import '../categories/category.dart';
import '../data/categories_data.dart';

/// 🧩 UI
import 'category_card.dart';

/// 🎨 Colors
import '../theme/app_colors.dart';

/// BottomSheet model
import '../widgets/add_expense_bottom_sheet.dart';

class MainCategoriesSection extends StatefulWidget {

  final int selectedIndex;
  final Function(int) onSelect;

  /// notifier للفئة المختارة
  final ValueNotifier<SelectedCategory> selectedCategory;

  const MainCategoriesSection({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.selectedCategory,
  });

  @override
  State<MainCategoriesSection> createState() =>
      _MainCategoriesSectionState();
}

class _MainCategoriesSectionState
    extends State<MainCategoriesSection> {

  late List<Category> categoriesList;

  static const double cardHeight = 50;
  static const double visibleRows = 3.2;

  @override
  void initState() {
    super.initState();
    categoriesList = List.from(mainCategories);
  }

  // =====================================================
  // 🗑 Delete BottomSheet
  // =====================================================
  void _showDeleteSheet(BuildContext context, int index) {

    final t = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {

        return Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(
                t.deleteCategory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// 🗑 Delete
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: Text(
                  t.delete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {

                  const minimumCategories = 3;

                  if (categoriesList.length <= minimumCategories) {
                    Navigator.pop(context);
                    return;
                  }

                  setState(() {

                    /// 🔥 حماية من crash
                    if (index < 0 ||
                        index >= categoriesList.length) return;

                    categoriesList.removeAt(index);
                  });

                  Navigator.pop(context);
                },
              ),

              /// ❌ Cancel
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(t.cancel),
                onTap: () => Navigator.pop(context),
              ),

            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    // =====================================================
    // 🚨 Safety Check (مهم جدًا)
    // =====================================================
    if (categoriesList.isEmpty) {
      return const SizedBox();
    }

    final double containerHeight =
        (cardHeight * visibleRows) + 20;

    final double screenWidth =
        MediaQuery.of(context).size.width;

    int columns;

    if (screenWidth < 100) {
      columns = 2;
    } else if (screenWidth < 200) {
      columns = 3;
    } else {
      columns = 4;
    }

    const double outerPadding = 12;
    const double innerPadding = 16;
    const double spacingBetweenCards = 7;

    final double horizontalPadding =
        outerPadding + innerPadding;

    final double spacing =
        (columns - 1) * spacingBetweenCards;

    final double cardWidth =
        (screenWidth - horizontalPadding - spacing) /
            columns;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),

      child: Container(

        height: containerHeight,
        padding: const EdgeInsets.all(5),

        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: AppColors.cardSecondary,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 12,
              offset: const Offset(0, 20),
            ),
          ],
        ),

        child: SingleChildScrollView(

          child: ReorderableWrap(

            spacing: spacingBetweenCards,
            runSpacing: spacingBetweenCards,
            needsLongPressDraggable: true,

            // =====================================================
            // 🔄 Reorder
            // =====================================================
            onReorder: (oldIndex, newIndex) {

              setState(() {

                /// 🔥 حماية
                if (oldIndex < 0 ||
                    oldIndex >= categoriesList.length ||
                    newIndex < 0 ||
                    newIndex > categoriesList.length) return;

                final item =
                    categoriesList.removeAt(oldIndex);

                categoriesList.insert(newIndex, item);

              });
            },

            children: List.generate(

              categoriesList.length,

              (index) {

                final category = categoriesList[index];

                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,

                  child: CategoryCard(

                    key: ValueKey('${category.id}_$index'),

                    categoryId: category.id,
                    title: category.title,

                    selected:
                        widget.selectedIndex == index,

                    selectedCategory:
                        widget.selectedCategory,

                    // =====================================================
                    // 👆 Tap
                    // =====================================================
                    onTap: () {

                      /// 🔥 حماية
                      if (index < 0 ||
                          index >= categoriesList.length) return;

                      widget.onSelect(index);
                    },

                    onLongPress: () =>
                        _showDeleteSheet(context, index),

                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
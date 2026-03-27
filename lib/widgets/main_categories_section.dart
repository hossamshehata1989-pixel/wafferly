import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import '../l10n/app_localizations.dart';
import '../config/category_config.dart'; // ✅ المسار الصحيح
import 'category_card.dart';
import 'add_expense_bottom_sheet.dart';

class MainCategoriesSection extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final ValueNotifier<SelectedCategory>? selectedCategory;

  const MainCategoriesSection({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.selectedCategory,
  });

  @override
  State<MainCategoriesSection> createState() => _MainCategoriesSectionState();
}

class _MainCategoriesSectionState extends State<MainCategoriesSection> {
  late List<CategoryConfig> categoriesList; // ✅ استخدام CategoryConfig
  static const double cardHeight = 65;
  static const double visibleRows = 3.2;

  @override
  void initState() {
    super.initState();
    // ✅ استخدام mainCategories من config
    categoriesList = List.from(mainCategories);
  }

  void _showDeleteSheet(BuildContext context, int index) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.deleteCategory,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(t.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                const minimumCategories = 3;
                if (categoriesList.length <= minimumCategories) {
                  Navigator.pop(context);
                  return;
                }
                setState(() {
                  categoriesList.removeAt(index);
                  if (widget.selectedIndex == index) widget.onSelect(-1);
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.white),
              title: Text(t.cancel, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final double containerHeight = (cardHeight * visibleRows) + 20;
    final double screenWidth = MediaQuery.of(context).size.width;

    int columns;
    if (screenWidth < 400) {
      columns = 4;
    } else if (screenWidth < 600) {
      columns = 5;
    } else if (screenWidth < 900) {
      columns = 6;
    } else {
      columns = 6;
    }

    const double outerPadding = 12;
    const double innerPadding = 16;
    const double spacingBetweenCards = 3;
    final double horizontalPadding = outerPadding + innerPadding;
    final double spacing = (columns - 1) * spacingBetweenCards;
    final double cardWidth = (screenWidth - horizontalPadding - spacing) / columns;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        height: containerHeight,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A6B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF243A8F)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: ReorderableWrap(
            spacing: spacingBetweenCards,
            runSpacing: spacingBetweenCards,
            needsLongPressDraggable: true,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < 0 ||
                    oldIndex >= categoriesList.length ||
                    newIndex < 0 ||
                    newIndex > categoriesList.length) {
                  return;
                }
                final item = categoriesList.removeAt(oldIndex);
                categoriesList.insert(newIndex, item);
              });
            },
            children: List.generate(categoriesList.length, (index) {
              final category = categoriesList[index];
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: CategoryCard(
                  key: ValueKey('${category.id}_$index'),
                  categoryId: category.id,
                  title: (t) => category.resolveTitle(t), // ✅ استخدام resolveTitle
                  selected: widget.selectedIndex == index,
                  selectedCategory: widget.selectedCategory,
                  onTap: () {
                    if (widget.selectedCategory != null) {
                      widget.selectedCategory!.value = SelectedCategory(
                        id: category.id,
                        name: category.resolveTitle(t),
                      );
                    }
                    widget.onSelect(index);
                  },
                  onLongPress: () => _showDeleteSheet(context, index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import '../data/categories_data.dart';
import 'category_card.dart';

class MainCategoriesSection extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const MainCategoriesSection({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<MainCategoriesSection> createState() =>
      _MainCategoriesSectionState();
}

class _MainCategoriesSectionState
    extends State<MainCategoriesSection> {
  late List categoriesList;

  static const double cardHeight = 130;
  static const int visibleRows = 2;

  @override
  void initState() {
    super.initState();
    categoriesList = List.from(categories);
  }

  /// 🔴 BottomSheet حذف فئة
  void _showDeleteSheet(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'حذف الفئة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              /// زر الحذف
              ListTile(
                leading:
                    const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  // منع حذف آخر كارت
                  if (categoriesList.length == 3) {
                    Navigator.pop(context);
                    return;
                  }

                  setState(() {
                    categoriesList.removeAt(index);
                  });
                  Navigator.pop(context);
                },
              ),

              /// إلغاء
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('إلغاء'),
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
    /// 🔹 ارتفاع الكونتينر (صفّين فقط)
    final double containerHeight =
        (cardHeight * visibleRows) + 20;

    /// 🔹 Responsive columns
    final double screenWidth = MediaQuery.of(context).size.width;

    int columns;
    if (screenWidth < 360) {
      columns = 2; // موبايلات صغيرة
    } else if (screenWidth < 600) {
      columns = 3; // موبايل عادي
    } else {
      columns = 4; // تابلت / شاشة كبيرة
    }

    const double outerPadding = 24; // Padding الشاشة
    const double innerPadding = 16; // Padding الكونتينر
    const double spacingBetweenCards = 10;

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        /// 🔽 Scroll رأسي + Drag & Drop
        child: SingleChildScrollView(
          child: ReorderableWrap(
            spacing: spacingBetweenCards,
            runSpacing: spacingBetweenCards,
            needsLongPressDraggable: true,

            /// إعادة ترتيب
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final item =
                    categoriesList.removeAt(oldIndex);
                categoriesList.insert(newIndex, item);
              });
            },

            children: List.generate(categoriesList.length,
                (index) {
              final category = categoriesList[index];

              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: CategoryCard(
                  key:
                      ValueKey('${category.titleKey}_$index'),
                  titleKey: category.titleKey,
                  selected:
                      widget.selectedIndex == index,
                  onTap: () => widget.onSelect(index),
                  onLongPress: () =>
                      _showDeleteSheet(context, index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

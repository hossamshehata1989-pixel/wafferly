// lib/widgets/expense_entry/sub_categories_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../config/category_config.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/category_icons.dart';

class SubCategoriesGrid extends StatelessWidget {
  final List<SubCategoryConfig> subCategories;
  final String selectedSubCategoryId;
  final Function(String) onSubCategorySelected;

  const SubCategoriesGrid({
    super.key,
    required this.subCategories,
    required this.selectedSubCategoryId,
    required this.onSubCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    const int fixedColumns = 5;
    final bool useTwoRows = subCategories.length > 10;

    const double spacing = 6;

    final double cardWidth =
        (screenWidth - 32 - ((fixedColumns - 1) * spacing)) / fixedColumns;

    final double cardHeight = useTwoRows ? cardWidth * 0.75 : cardWidth * 0.75;
    final double iconSize = cardWidth * 0.25;
    final double fontSize = cardWidth * 0.07;

    final double listHeight = useTwoRows
        ? ((cardHeight * 2) + spacing).ceilToDouble()
        : cardHeight;

    final int rows = useTwoRows ? 2 : 1;
    final int columns = (subCategories.length / rows).ceil();

    return SizedBox(
      height: listHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(columns, (columnIndex) {
            return Padding(
              padding: EdgeInsets.only(
                right: columnIndex == columns - 1 ? 0 : spacing,
              ),
              child: Column(
                children: List.generate(rows, (rowIndex) {
                  final int itemIndex = columnIndex + (rowIndex * columns);

                  if (itemIndex >= subCategories.length) {
                    return SizedBox(width: cardWidth, height: cardHeight);
                  }

                  final sub = subCategories[itemIndex];
                  final isSelected = selectedSubCategoryId == sub.id;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: rowIndex == rows - 1 ? 0 : spacing,
                    ),
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _buildSubCategoryCard(
                        sub: sub,
                        isSelected: isSelected,
                        iconSize: iconSize,
                        fontSize: fontSize,
                        cardWidth: cardWidth,
                        onTap: () => onSubCategorySelected(sub.id),
                        t: t,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard({
    required SubCategoryConfig sub,
    required bool isSelected,
    required double iconSize,
    required double fontSize,
    required double cardWidth,
    required VoidCallback onTap,
    required AppLocalizations t,
  }) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A7BFF) : const Color(0xFF243A8F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4FD1FF)
                : const Color(0xFF3A7BFF).withOpacity(0.5),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3A7BFF).withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white24,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    getCategoryIcon(sub.id),
                    width: iconSize,
                    height: iconSize,
                    colorFilter: isSelected
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : null,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.category,
                      size: iconSize,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
                    child: AutoSizeText(
                      sub.title(t),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      minFontSize: 9,
                      stepGranularity: 0.5,
                      overflowReplacement: const SizedBox.shrink(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: fontSize.clamp(9.0, 12.0),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

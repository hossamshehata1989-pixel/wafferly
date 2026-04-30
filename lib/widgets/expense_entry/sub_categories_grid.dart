// lib/widgets/expense_entry/sub_categories_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../config/category_config.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/category_icons.dart';
import '../../theme/app_colors.dart';

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
    
    const int columns = 5;
    final int totalItems = subCategories.length;
    final int requiredRows = (totalItems / columns).ceil();
    final int visibleRows = requiredRows > 2 ? 2 : requiredRows;
    final bool needsScroll = requiredRows > 2;
    
    final double cardWidth = (screenWidth - 32 - (columns - 1) * 6) / columns;
    final double cardHeight = cardWidth * 0.85;
    final double totalHeight = visibleRows * (cardHeight + 6);
    final double iconSize = cardWidth * 0.35;
    final double fontSize = cardWidth * 0.11;
    
    return RepaintBoundary(
      child: SizedBox(
        height: totalHeight,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: needsScroll 
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            final sub = subCategories[index];
            final isSelected = selectedSubCategoryId == sub.id;
            
            return Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3A7BFF) : const Color(0xFF243A8F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4FD1FF) : const Color(0xFF3A7BFF).withOpacity(0.5),
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
                    onTap: () => onSubCategorySelected(sub.id),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Colors.white24,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
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
                          const SizedBox(height: 6),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
                            child: AutoSizeText(
                              sub.title(t),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              minFontSize: 9,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: fontSize.clamp(9.0, 13.0),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          },
        ),
      ),
    );
  }
}
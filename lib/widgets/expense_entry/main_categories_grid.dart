// lib/widgets/expense_entry/main_categories_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/category_config.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class MainCategoriesGrid extends StatelessWidget {
  final String selectedCategoryId;
  final Function(String) onCategorySelected;
  final double availableHeight;

  const MainCategoriesGrid({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 5;
    } else if (screenWidth < 900) {
      crossAxisCount = 6;
    } else if (screenWidth < 1200) {
      crossAxisCount = 7;
    } else {
      crossAxisCount = 8;
    }
    
    final double cardWidth = (screenWidth - 32 - (crossAxisCount - 1) * 6) / crossAxisCount;
    final double cardHeight = cardWidth * 0.9;
    
    final int totalItems = mainCategories.length;
    final int requiredRows = (totalItems / crossAxisCount).ceil();
    final double totalGridHeight = requiredRows * (cardHeight + 6);
    final bool needsScroll = totalGridHeight > availableHeight;
    
    return RepaintBoundary(
      child: SizedBox(
        height: needsScroll ? availableHeight : totalGridHeight,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: needsScroll 
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: cardWidth / cardHeight,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            final category = mainCategories[index];
            final isSelected = selectedCategoryId == category.id ||
                (category.subCategories?.any((s) => s.id == selectedCategoryId) ?? false);
            
            return _buildCategoryCard(
              title: category.resolveTitle(t),
              iconPath: category.icon,
              isSelected: isSelected,
              cardWidth: cardWidth,
              onTap: () => onCategorySelected(category.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String iconPath,
    required bool isSelected,
    required double cardWidth,
    required VoidCallback onTap,
  }) {
    final double iconSize = cardWidth * 0.4;
    final double fontSize = cardWidth * 0.11;
    
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A7BFF) : const Color(0xFF1B2A6B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4FD1FF) : const Color(0xFF243A8F),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3A7BFF).withOpacity(0.4),
                    blurRadius: 8,
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
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    iconPath,
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
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: fontSize.clamp(9.0, 14.0),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          height: 1.2,
                        ),
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
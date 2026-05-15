// lib/features/analysis/widgets/category_detail_row.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../registry/category_registry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';

/// Pure UI widget - displays a single category row
/// All lookups go through CategoryRegistry
class CategoryDetailRow extends StatelessWidget {
  final String categoryId;
  final double amount;
  final double total;
  final VoidCallback onTap;

  const CategoryDetailRow({
    super.key,
    required this.categoryId,
    required this.amount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final percentage = total > 0 ? (amount / total) * 100 : 0;
    final color = CategoryRegistry.getColor(categoryId);
    final iconPath = CategoryRegistry.getIcon(categoryId);
    final name = CategoryRegistry.getMainCategoryName(categoryId, t);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildIcon(iconPath, color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount, 'EGP'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          _buildDetailsButton(t, color),
        ],
      ),
    );
  }

  Widget _buildIcon(String? iconPath, Color color) {
    if (iconPath == null) {
      return Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.category, size: 20, color: color),
      );
    }

    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        iconPath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.category, size: 20, color: color),
      ),
    );
  }

  Widget _buildDetailsButton(AppLocalizations t, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(t.details, style: TextStyle(color: color, fontSize: 10)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 10, color: color),
          ],
        ),
      ),
    );
  }
}

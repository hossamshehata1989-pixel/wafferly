// lib/features/analysis/widgets/sub_category_row.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../registry/category_registry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';

class SubCategoryRow extends StatelessWidget {
  final String subCategoryId;
  final double amount;
  final double total;
  final String currencyCode;

  const SubCategoryRow({
    super.key,
    required this.subCategoryId,
    required this.amount,
    required this.total,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final percentage = total > 0 ? (amount / total) * 100 : 0;
    final color = CategoryRegistry.getColor(subCategoryId);
    final iconPath = CategoryRegistry.getIcon(subCategoryId);
    final name = CategoryRegistry.getSubCategoryName(subCategoryId, t);

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
            CurrencyFormatter.format(amount, currencyCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String? iconPath, Color color) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: iconPath == null
          ? Icon(Icons.category, size: 24, color: color)
          : SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.category, size: 24, color: color),
            ),
    );
  }
}

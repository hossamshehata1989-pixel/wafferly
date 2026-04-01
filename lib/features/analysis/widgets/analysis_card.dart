// lib/features/analysis/widgets/analysis_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalysisCard extends StatelessWidget {
  final String title;
  final double amount;
  final double changePercentage;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompareActive;
  final VoidCallback? onCompareTap; // ✅ اجعله optional

  const AnalysisCard({
    super.key,
    required this.title,
    required this.amount,
    required this.changePercentage,
    required this.color,
    this.isSelected = false,
    required this.onTap,
    this.isCompareActive = false,
    this.onCompareTap, // ✅ optional
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color : const Color(0xFF2A2A2A),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // ✅ محتوى الكارت
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  "${formatter.format(amount.toInt())} EGP",
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      changePercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: changePercentage >= 0 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${changePercentage >= 0 ? '+' : ''}${changePercentage.toStringAsFixed(0)}% Vs Last month",
                        style: TextStyle(
                          color: changePercentage >= 0 ? Colors.red : Colors.green,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // ✅ زر المقارنة الصغير في أعلى اليمين (يظهر فقط إذا كان onCompareTap موجود)
            if (onCompareTap != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onCompareTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCompareActive ? color : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.compare,
                      size: 14,
                      color: isCompareActive ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
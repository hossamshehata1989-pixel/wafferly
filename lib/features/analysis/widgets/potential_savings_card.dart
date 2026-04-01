// lib/features/analysis/widgets/potential_savings_card.dart
import 'package:flutter/material.dart';
import '../../../models/expense.dart';

class PotentialSavingsCard extends StatelessWidget {
  final List<Expense> expenses;
  final double budget;

  const PotentialSavingsCard({
    super.key,
    required this.expenses,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final daysRemaining = DateTime.now().difference(DateTime(DateTime.now().year, DateTime.now().month, 1)).inDays + 1;
    final dailyAverage = total / daysRemaining;
    final projectedTotal = dailyAverage * DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    
    final willExceed = projectedTotal > budget;
    final daysToExceed = willExceed ? ((budget - total) / dailyAverage).ceil() : null;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: willExceed ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        border: Border.all(
          color: willExceed ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: willExceed ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              willExceed ? Icons.warning_amber_rounded : Icons.savings,
              color: willExceed ? Colors.red : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  willExceed 
                    ? "⚠️ Potential Budget Exceed"
                    : "✅ On Track",
                  style: TextStyle(
                    color: willExceed ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  willExceed
                    ? "If you continue this trend, you might exceed your budget in $daysToExceed days. Try cutting down on unnecessary expenses."
                    : "You're within budget! Keep up the good spending habits.",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
// lib/features/analysis/widgets/insight_card.dart
import 'package:flutter/material.dart';
import '../../../models/expense.dart';

class InsightCard extends StatelessWidget {
  final List<Expense> expenses;
  final VoidCallback onSetBudget;

  const InsightCard({
    super.key,
    required this.expenses,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    // تحليل الفئة الأكبر إنفاقاً
    final categoryMap = <String, double>{};
    for (final expense in expenses) {
      categoryMap[expense.mainCategory] = 
          (categoryMap[expense.mainCategory] ?? 0) + expense.amount;
    }
    
    final sorted = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategory = sorted.isNotEmpty ? sorted.first : null;
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final topPercentage = topCategory != null && total > 0 
        ? (topCategory.value / total) * 100 
        : 0;
    
    // تقدير التوفير المحتمل (20% من الفئة الأكبر)
    final potentialSavings = topCategory != null 
        ? (topCategory.value * 0.2).toInt() 
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3A7BFF).withOpacity(0.2),
            const Color(0xFF1B2A6B).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF3A7BFF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFF3A7BFF), size: 20),
              SizedBox(width: 8),
              Text(
                "Insights",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topCategory != null)
            Text(
              "You're spending ${topPercentage.toStringAsFixed(0)}% on ${_getCategoryName(topCategory.key)}. "
              "Consider reducing this to save around $potentialSavings EGP.",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onSetBudget,
              child: const Text(
                "Set a budget",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getCategoryName(String id) {
    final names = {
      'dailyTransport': 'Transport',
      'bills': 'Bills',
      'supermarket': 'Food',
      'fastFood': 'Fast Food',
      'entertainment': 'Entertainment',
    };
    return names[id] ?? id;
  }
}
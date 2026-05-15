// lib/features/analysis/widgets/analysis_summary_card.dart

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Pure UI widget - no business logic
/// Receives pre-formatted data from parent
class AnalysisSummaryCard extends StatelessWidget {
  final String title;
  final String formattedAmount;
  final double? change;
  final Color color;

  const AnalysisSummaryCard({
    super.key,
    required this.title,
    required this.formattedAmount,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            formattedAmount,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildChangeIndicator(t),
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(AppLocalizations t) {
    if (change == null) {
      return Text(
        t.noComparisonData,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      );
    }

    if (change == 0) {
      return Text(
        "0% ${t.vsLastPeriod}",
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      );
    }

    final isPositive = change! > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: isPositive ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          "${isPositive ? '+' : ''}${change!.toStringAsFixed(0)}% ${t.vsLastPeriod}",
          style: TextStyle(
            color: isPositive ? Colors.red : Colors.green,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

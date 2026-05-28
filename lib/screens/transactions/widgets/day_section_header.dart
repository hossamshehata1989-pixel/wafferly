import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final double totalAmount;
  final int selectedTab;

  const DaySectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.totalAmount,
    required this.selectedTab,
  });

  String _buildSummaryText() {
    if (selectedTab == 3) {
      return '';
    }

    final formatted = NumberFormat("#,###").format(totalAmount.abs().toInt());

    switch (selectedTab) {
      case 1:
        return '-$formatted EGP';

      case 2:
        return '+$formatted EGP';

      default:
        final sign = totalAmount >= 0 ? '+' : '-';
        return '$sign$formatted EGP';
    }
  }

  String _buildTransactionsLabel() {
    if (selectedTab == 3) {
      return '$count transactions';
    }

    return '$count transactions • ${_buildSummaryText()}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),

          const Spacer(),
          Flexible(
            child: Text(
              _buildTransactionsLabel(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color.fromARGB(183, 255, 255, 255),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

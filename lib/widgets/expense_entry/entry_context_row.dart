// lib/widgets/expense_entry/entry_context_row.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import '../../features/transactions/models/entry_mode.dart';

class EntryContextRow extends StatelessWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;
  final VoidCallback? onAccountTap;
  final EntryMode mode;
  const EntryContextRow({
    super.key,
    required this.controller,
    required this.metrics,
    this.onAccountTap,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _infoButton(metrics, Icons.calendar_today_outlined, 'Today'),
        ),
        SizedBox(width: metrics.spacing(6)),
        Expanded(
          child: _infoButton(
            metrics,
            Icons.account_balance_wallet_outlined,
            controller.selectedAccountName,
            onTap: onAccountTap,
          ),
        ),
        SizedBox(width: metrics.spacing(6)),
        Expanded(child: _infoButton(metrics, Icons.person_outline, 'Me')),
        SizedBox(width: metrics.spacing(6)),
        Expanded(
          child: _infoButton(metrics, Icons.check_circle_outline, 'Done'),
        ),
      ],
    );
  }

  Widget _infoButton(
    ResponsiveMetrics metrics,
    IconData icon,
    String text, {
    VoidCallback? onTap,
  }) {
    final isSmallScreen = metrics.width < 360;
    final double height = isSmallScreen ? metrics.h(38) : metrics.h(45);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.calculatorButton,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: metrics.size(15), color: Colors.white70),
            SizedBox(width: metrics.spacing(4)),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: metrics.text(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

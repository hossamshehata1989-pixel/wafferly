// lib/widgets/expense_entry/entry_context_row.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import '../../features/transactions/models/entry_mode.dart';
import '../../features/transactions/models/entry_mode_extension.dart';
import 'date_picker_sheet.dart';
import '../../widgets/bottom_sheet/wafferly_bottom_sheet.dart';
import 'account_button.dart'; // ✅ استيراد AccountButton

class EntryContextRow extends StatelessWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;
  final EntryMode mode;

  const EntryContextRow({
    super.key,
    required this.controller,
    required this.metrics,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _infoButton(
            metrics,
            Icons.calendar_today_outlined,
            controller.transactionDateLabel,
            onTap: () {
              WafferlyBottomSheet.show(
                context: context,
                child: DatePickerSheet(controller: controller),
              );
            },
          ),
        ),
        SizedBox(width: metrics.spacing(6)),
        Expanded(
          child: AccountButton(
            controller: controller,
            metrics: metrics,
            mode: mode,
          ),
        ),
        SizedBox(width: metrics.spacing(6)),
        Expanded(child: _infoButton(metrics, Icons.person_outline, 'Me')),
        SizedBox(width: metrics.spacing(6)),
        Expanded(
          child: _infoButton(
            metrics,
            Icons.check_circle_outline,
            'Done',
            onTap: () {
              debugPrint('Done tapped');
            },
          ),
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
            Expanded(
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

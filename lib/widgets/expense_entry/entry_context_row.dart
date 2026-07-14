// lib/widgets/expense_entry/entry_context_row.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/responsive_metrics.dart';
import '../../features/transactions/models/entry_mode.dart';
import 'date/date_picker_sheet.dart';
import '../../widgets/bottom_sheet/wafferly_bottom_sheet.dart';
import 'account/account_button.dart';
import 'entry_context_chip.dart';
import 'member/member_button.dart';

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
          child: EntryContextChip(
            metrics: metrics,
            leading: Icon(
              Icons.calendar_today_outlined,
              color: Colors.white70,
              size: 17,
            ),
            iconColor: Colors.white70,
            label: controller.transactionDateLabel,
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
        Expanded(
          child: MemberButton(controller: controller, metrics: metrics),
        ),
        SizedBox(width: metrics.spacing(6)),
        Expanded(
          child: EntryContextChip(
            metrics: metrics,
            leading: Icon(
              Icons.check_circle_outline,
              color: Colors.white70,
              size: 17,
            ),
            iconColor: Colors.white70,
            label: 'Done',
            onTap: () {
              debugPrint('Done tapped');
            },
          ),
        ),
      ],
    );
  }
}

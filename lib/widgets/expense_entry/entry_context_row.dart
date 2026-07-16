import 'package:flutter/material.dart';

import '../../controllers/transaction_entry_controller.dart';
import '../../features/transactions/models/entry_mode.dart';
import '../../features/transactions/models/entry_state.dart';
import '../../theme/responsive_metrics.dart';
import '../../widgets/bottom_sheet/wafferly_bottom_sheet.dart';

import 'account/account_button.dart';
import 'date/date_picker_sheet.dart';
import 'discard_entry_sheet.dart';
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
            leading: const Icon(
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
            leading: const Icon(
              Icons.check_circle_outline,
              color: Colors.white70,
              size: 17,
            ),
            iconColor: Colors.white70,
            label: 'Done',
            onTap: () => _handleDone(context),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDone(BuildContext context) async {
    // شاشة فاضية -> اقفل
    if (controller.entryState == EntryState.empty) {
      Navigator.pop(context);
      return;
    }

    // حاول تحفظ أولاً
    final result = await controller.saveEntry();

    if (!context.mounted) return;

    // نجح -> اقفل الشاشة
    if (result.success) {
      Navigator.pop(context);
      return;
    }

    // Validation Errors
    switch (result.action) {
      case SaveAction.invalidAmount:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;

      case SaveAction.noCategorySelected:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select category')));
        return;

      case SaveAction.noAccountSelected:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select account')));
        return;

      default:
        break;
    }

    // لو فيه Draft اعرض شاشة Discard
    if (controller.entryState == EntryState.draft) {
      await WafferlyBottomSheet.show(
        context: context,
        child: DiscardEntrySheet(
          onDiscard: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
      return;
    }

    // أي Error آخر
    if (result.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
    }
  }
}

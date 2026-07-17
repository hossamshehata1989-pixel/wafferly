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
import '../bottom_sheet/bottom_sheet_theme.dart';
import '../notifications/wafferly_toast.dart';

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
    switch (controller.entryState) {
      case EntryState.empty:
        Navigator.pop(context, true);
        return;

      case EntryState.draft:
        await WafferlyBottomSheet.show(
          context: context,
          theme: BottomSheetTheme.glass,

          child: DiscardEntrySheet(
            onDiscard: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
        return;

      case EntryState.readyToSave:
        final result = await controller.submitEntry();

        if (!context.mounted) return;

        if (!result.success) {
          switch (result.action) {
            case SaveAction.invalidAmount:
              WafferlyToast.showError(
                context,
                message: "Please enter a valid amount",
              );
              return;

            case SaveAction.noCategorySelected:
              WafferlyToast.showError(
                context,
                message: "Please enter a valid amount",
              );
              return;

            case SaveAction.noAccountSelected:
              WafferlyToast.showError(
                context,
                message: "Please select an account",
              );
              (const SnackBar(content: Text('Please select account')),);
              return;

            default:
              if (result.errorMessage != null) {
                WafferlyToast.showError(context, message: result.errorMessage!);
              }
              return;
          }
        }

        WafferlyToast.showSuccess(context, message: "Transaction saved");

        await Future.delayed(const Duration(milliseconds: 1200));

        if (!context.mounted) return;

        Navigator.pop(context, true);
        return;
    }
  }
}

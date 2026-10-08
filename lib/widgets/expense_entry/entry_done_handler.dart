// lib/widgets/expense_entry/entry_done_handler.dart

import 'package:flutter/material.dart';

import '../../controllers/transaction_entry_controller.dart';
import '../../features/transactions/models/entry_state.dart';
import '../bottom_sheet/bottom_sheet_theme.dart';
import '../bottom_sheet/wafferly_bottom_sheet.dart';
import '../notifications/wafferly_toast.dart';
import 'discard_entry_sheet.dart';

/// Shared "Done" behaviour for every entry mode.
///
/// - empty entry      -> close the screen
/// - draft (unsaved)  -> ask before discarding
/// - ready to save    -> save, then close
///
/// "Add" is different: it saves and keeps the screen open for the next entry.
Future<void> handleEntryDone(
  BuildContext context,
  TransactionEntryController controller,
) async {
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
              message: 'Please enter a valid amount',
            );
            return;

          case SaveAction.noCategorySelected:
            WafferlyToast.showError(
              context,
              message: 'Please select a category',
            );
            return;

          case SaveAction.noAccountSelected:
            WafferlyToast.showError(
              context,
              message: 'Please select an account',
            );
            return;

          default:
            if (result.errorMessage != null) {
              WafferlyToast.showError(context, message: result.errorMessage!);
            }
            return;
        }
      }

      WafferlyToast.showSuccess(context, message: 'Transaction saved');

      await Future.delayed(const Duration(milliseconds: 1200));

      if (!context.mounted) return;

      Navigator.pop(context, true);
      return;
  }
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../controllers/transaction_entry_controller.dart';
import '../../features/transactions/models/entry_mode.dart';
import '../../features/transactions/models/expense_payment_mode.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import '../../widgets/bottom_sheet/wafferly_bottom_sheet.dart';

import 'account/account_button.dart';
import 'date/date_picker_sheet.dart';
import 'entry_done_handler.dart';
import 'entry_context_chip.dart';
import 'member/member_button.dart';
import '../notifications/wafferly_toast.dart';
import 'payment_method_sheet.dart';
import '../../l10n/app_localizations.dart';

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
    if (mode == EntryMode.expense) {
      return _buildExpenseContextRow(context);
    }

    return Row(
      // Stable physical order, independent of the selected locale.
      textDirection: ui.TextDirection.ltr,
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
            label: AppLocalizations.of(context)!.done,
            onTap: () => _handleDone(context),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseContextRow(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final canOpenInstallment = controller.canOpenExpenseInstallment &&
        !(controller.isCreditCardEntryContext && !controller.isCreditCardInstallmentOnly);
    const installmentColor = Color(0xFFD36BFF);

    return Row(
      // Stable physical order, independent of the selected locale.
      textDirection: ui.TextDirection.ltr,
      children: [
        Expanded(
          flex: 10,
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
        SizedBox(width: metrics.spacing(5)),
        Expanded(
          flex: 15,
          child: AccountButton(
            controller: controller,
            metrics: metrics,
            mode: mode,
            showPaymentModeLabel: true,
          ),
        ),
        SizedBox(width: metrics.spacing(5)),
        Expanded(
          flex: 13,
          child: EntryContextChip(
            metrics: metrics,
            leading: const Icon(
              Icons.bar_chart_rounded,
              color: installmentColor,
              size: 18,
            ),
            iconColor: installmentColor,
            label: t.installment,
            centeredContent: true,
            backgroundColor: canOpenInstallment
                ? AppColors.cardSecondary
                : AppColors.background.withValues(alpha: .55),
            borderColor: canOpenInstallment
                ? installmentColor.withValues(alpha: .28)
                : Colors.white10,
            onTap: canOpenInstallment ? () => _openInstallment(context) : null,
          ),
        ),
        SizedBox(width: metrics.spacing(5)),
        Expanded(
          flex: 10,
          child: MemberButton(controller: controller, metrics: metrics),
        ),
      ],
    );
  }

  Future<void> _openInstallment(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    if (!controller.hasCategory) {
      WafferlyToast.showError(context, message: t.pleaseSelectCategory);
      return;
    }
    if (!controller.hasAmount) {
      WafferlyToast.showError(context, message: t.pleaseEnterValidAmount);
      return;
    }

    // The Installment control is the only action that opens the installment
    // details sheet. On success, close the entry screen and refresh its caller.
    final completed = await showPaymentMethodSheet(
      context: context,
      controller: controller,
      initialMode: ExpensePaymentMode.installment,
      installmentOnly: true,
    );
    if (completed && context.mounted && controller.isCreditCardInstallmentOnly) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleDone(BuildContext context) =>
      handleEntryDone(context, controller);
}

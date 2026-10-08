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

  /// Account (Full Payment), Installment and Add stay locked until the user
  /// has picked a category and entered an amount. Date and member are
  /// always available.
  static const _lockedMessage = 'Choose a category and enter an amount first';

  Widget _gated({
    required BuildContext context,
    required bool locked,
    required Widget child,
  }) {
    if (!locked) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => WafferlyToast.showError(context, message: _lockedMessage),
      child: Opacity(
        opacity: .45,
        child: AbsorbPointer(child: child),
      ),
    );
  }

  Widget _buildExpenseContextRow(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final unlocked = controller.hasCategory && controller.hasAmount;
        const installmentColor = Color(0xFFD36BFF);

        return Row(
          children: [
            Expanded(
              flex: 8,
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
              flex: 17,
              child: _gated(
                context: context,
                locked: !unlocked,
                child: AccountButton(
                  controller: controller,
                  metrics: metrics,
                  mode: mode,
                  showPaymentModeLabel: true,
                ),
              ),
            ),
            SizedBox(width: metrics.spacing(5)),
            Expanded(
              flex: 13,
              child: _gated(
                context: context,
                locked: !unlocked,
                child: EntryContextChip(
                  metrics: metrics,
                  leading: const Icon(
                    Icons.bar_chart_rounded,
                    color: installmentColor,
                    size: 18,
                  ),
                  iconColor: installmentColor,
                  label: 'Installment',
                  backgroundColor: AppColors.cardSecondary,
                  borderColor: installmentColor.withValues(alpha: .28),
                  onTap: () => _openInstallment(context),
                ),
              ),
            ),
            SizedBox(width: metrics.spacing(5)),
            Expanded(
              flex: 8,
              child: MemberButton(controller: controller, metrics: metrics),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openInstallment(BuildContext context) async {
    await showPaymentMethodSheet(
      context: context,
      controller: controller,
      initialMode: ExpensePaymentMode.installment,
      installmentOnly: true,
    );
  }

  Future<void> _handleDone(BuildContext context) =>
      handleEntryDone(context, controller);
}

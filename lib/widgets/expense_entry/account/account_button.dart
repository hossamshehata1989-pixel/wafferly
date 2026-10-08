import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wafferly/controllers/transaction_entry_controller.dart';
import 'package:wafferly/theme/responsive_metrics.dart';
import 'package:wafferly/theme/app_colors.dart';
import 'package:wafferly/features/transactions/models/entry_mode.dart';
import 'package:wafferly/models/account_display_extension.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/widgets/expense_entry/entry_context_chip.dart';
import 'package:wafferly/widgets/expense_entry/account/account_selector.dart';
import 'package:wafferly/widgets/expense_entry/account/no_account_sheet.dart';
import 'package:wafferly/widgets/bottom_sheet/wafferly_bottom_sheet.dart';
import 'package:wafferly/widgets/expense_entry/payment_method_sheet.dart';

class AccountButton extends StatefulWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;
  final EntryMode mode;
  final bool showPaymentModeLabel;

  const AccountButton({
    super.key,
    required this.controller,
    required this.metrics,
    required this.mode,
    this.showPaymentModeLabel = false,
  });

  @override
  State<AccountButton> createState() => _AccountButtonState();
}

class _AccountButtonState extends State<AccountButton> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final accounts = widget.controller.availableAccounts;
        final selectedId = widget.controller.selectedAccountId;

        Account? selectedAccount = accounts
            .where((acc) => acc.id == selectedId)
            .firstOrNull;

        // Expense entry may intentionally select a Savings, Prepaid, or
        // Credit Card source. Resolve it directly instead of forcing it back
        // into the liquidity-only list.
        if (selectedAccount == null && selectedId.isNotEmpty) {
          final resolved = Hive.box<Account>('accounts').get(selectedId);
          if (resolved != null &&
              !resolved.isArchived &&
              resolved.bookId == 'default') {
            if (resolved.type == 'creditCard' ||
                resolved.group == AccountGroup.savings ||
                resolved.type == 'prepaid') {
              selectedAccount = resolved;
            }
          }
        }

        final isLockedCreditCardEdit =
            widget.controller.isEditing && widget.controller.isCreditCardCharge;
        final hasPaymentSources = widget.controller.hasExpensePaymentSources;
        final showPaymentPicker =
            widget.controller.isExpense && hasPaymentSources;

        if (selectedAccount == null) {
          return EntryContextChip(
            key: _anchorKey,
            metrics: widget.metrics,
            label: widget.showPaymentModeLabel
                ? 'Full Payment'
                : (showPaymentPicker ? 'Select Payment' : 'No Account'),
            iconColor: Colors.white54,
            onTap: showPaymentPicker ? _handleTap : _showNoAccountSheet,
          );
        }

        final display = selectedAccount.display;
        final showChevron = !isLockedCreditCardEdit && hasPaymentSources;

        if (widget.showPaymentModeLabel) {
          return AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            child: Material(
              color: AppColors.calculatorButton,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                key: _anchorKey,
                onTap: isLockedCreditCardEdit ? null : _handleTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: widget.metrics.width < 360 || widget.metrics.isCompactHeight
                      ? widget.metrics.h(42)
                      : widget.metrics.h(48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: display.color.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(display.icon, color: display.color, size: 16),
                      SizedBox(width: widget.metrics.spacing(4)),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Full Payment',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedAccount.name,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (showChevron) ...[
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: EntryContextChip(
            key: _anchorKey,
            metrics: widget.metrics,
            leading: Icon(display.icon, color: display.color, size: 17),
            iconColor: display.color,
            label: selectedAccount.name,
            trailing: showChevron
                ? Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: display.color,
                  )
                : null,
            borderColor: display.color.withValues(alpha: 0.20),
            onTap: isLockedCreditCardEdit ? null : _handleTap,
          ),
        );

      },
    );
  }

  Future<void> _handleTap() async {
    setState(() => _pressed = true);

    await Future.delayed(const Duration(milliseconds: 80));

    if (mounted) {
      setState(() => _pressed = false);
    }

    if (!mounted) return;

    if (widget.controller.shouldOpenPaymentMethodSheet) {
      await showPaymentMethodSheet(
        context: context,
        controller: widget.controller,
      );
      return;
    }

    await AccountSelector.show(
      context: context,
      controller: widget.controller,
      anchorKey: _anchorKey,
    );
  }


  Future<void> _showNoAccountSheet() async {
    await WafferlyBottomSheet.show(
      context: context,
      child: const NoAccountSheet(),
    );
  }
}

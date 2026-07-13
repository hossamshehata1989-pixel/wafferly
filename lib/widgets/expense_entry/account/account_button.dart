// lib/widgets/expense_entry/account/account_button.dart

import 'package:flutter/material.dart';
import '../../../controllers/transaction_entry_controller.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../features/transactions/models/entry_mode.dart';
import '../../../models/account_display_extension.dart';

import '../entry_context_chip.dart';
import 'account_selector.dart';
import 'no_account_sheet.dart';

import '../../bottom_sheet/wafferly_bottom_sheet.dart';

class AccountButton extends StatefulWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;
  final EntryMode mode;

  const AccountButton({
    super.key,
    required this.controller,
    required this.metrics,
    required this.mode,
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

        final selectedAccount = accounts
            .where((acc) => acc.id == selectedId)
            .firstOrNull;

        if (selectedAccount == null) {
          return EntryContextChip(
            key: _anchorKey,
            metrics: widget.metrics,
            label: 'No Account',
            iconColor: Colors.white54, // ✅ تم توفير اللون
            onTap: _showNoAccountSheet,
          );
        }

        final display = selectedAccount.display;
        final accountCount = accounts.length;

        return AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: EntryContextChip(
            key: _anchorKey,
            metrics: widget.metrics,
            icon: display.icon,
            iconColor: display.color,
            label: selectedAccount.name,
            trailing: accountCount > 1
                ? Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: display.color,
                  )
                : null,
            borderColor: display.color.withValues(alpha: 0.20),
            onTap: _handleTap,
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

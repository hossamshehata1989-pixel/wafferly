// lib/widgets/expense_entry/entry_bottom_actions.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import '../../financial_engine/resolution/resolution.dart';
import '../../features/transactions/models/entry_mode.dart';
import '../../features/transactions/models/entry_mode_extension.dart';
import '../notifications/wafferly_toast.dart';

class EntryBottomActions extends StatelessWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;
  final EntryMode mode;

  const EntryBottomActions({
    super.key,
    required this.controller,
    required this.metrics,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _bottomActionButton(metrics, '', Icons.more_horiz)),
        SizedBox(width: metrics.spacing(6)),
        Expanded(flex: 2, child: _buildPrimaryAction(context, metrics)),
        SizedBox(width: metrics.spacing(6)),
        Expanded(child: _bottomActionButton(metrics, '', Icons.mic)),
      ],
    );
  }

  Widget _bottomActionButton(
    ResponsiveMetrics metrics,
    String text,
    IconData icon,
  ) {
    final isSmallScreen = metrics.width < 360;
    final double height = isSmallScreen ? metrics.h(38) : metrics.h(45);
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: metrics.spacing(8)),
        ),
        child: FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: metrics.size(15)),
              if (text.isNotEmpty) ...[
                SizedBox(width: metrics.spacing(4)),
                Text(text, style: TextStyle(fontSize: metrics.text(13))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context, ResponsiveMetrics metrics) {
    switch (mode) {
      case EntryMode.expense:
        return _buildExpenseAction(context, metrics);
      case EntryMode.income:
        return _buildIncomeAction(context, metrics);
      case EntryMode.transfer:
        return _buildTransferAction(context, metrics);
    }
  }

  Widget _buildExpenseAction(BuildContext context, ResponsiveMetrics metrics) {
    final config = mode.config;
    final double height = metrics.width < 360 ? metrics.h(38) : metrics.h(45);

    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: InkWell(
                onTap: controller.toggleExceptional,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: controller.isExceptional
                        ? Colors.amber.withOpacity(0.35)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Exceptional',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.help_outline, size: 13, color: Colors.amber),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                onTap: () => _submitEntry(context),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        config.submitButtonTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeAction(BuildContext context, ResponsiveMetrics metrics) {
    final config = mode.config;
    final double height = metrics.width < 360 ? metrics.h(38) : metrics.h(45);

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () => _submitEntry(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white),
            SizedBox(width: metrics.spacing(6)),
            Text(
              config.submitButtonTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: metrics.text(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferAction(BuildContext context, ResponsiveMetrics metrics) {
    return _buildExpenseAction(context, metrics);
  }

  Future<void> _submitEntry(BuildContext context) async {
    final result = await controller.submitEntry();

    if (!result.success) {
      switch (result.action) {
        case SaveAction.invalidAmount:
          WafferlyToast.showError(
            context,
            message: "Please enter a valid amount",
          );
          return;

        case SaveAction.noCategorySelected:
          WafferlyToast.showError(context, message: "Please select a category");
          return;

        case SaveAction.noAccountSelected:
          WafferlyToast.showError(context, message: "Please select an account");
          return;

        default:
          if (result.errorMessage != null) {
            WafferlyToast.showError(context, message: result.errorMessage!);
          }
          return;
      }
    }

    // داخل _submitEntry()

    if (result.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: const Text('Choose how you want to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        WafferlyToast.showSuccess(context, message: "Transaction saved");
      }

      return;
    }

    if (result.success) {
      WafferlyToast.showSuccess(context, message: "Transaction saved");
    }
  }
}

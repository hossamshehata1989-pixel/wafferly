// lib/widgets/expense_entry/entry_bottom_actions.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import '../../financial_engine/resolution/resolution.dart';
import '../../features/transactions/models/entry_mode.dart';
import '../../features/transactions/models/entry_mode_extension.dart'; // 👈 استيراد جديد

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

  // ============================================================
  // 1) _buildPrimaryAction – يختار الدالة المناسبة حسب mode
  // ============================================================
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

  // ============================================================
  // 2) _buildExpenseAction – UI only (الزر الخاص بالمصروفات)
  // ============================================================
  Widget _buildExpenseAction(BuildContext context, ResponsiveMetrics metrics) {
    final config = mode.config; // 👈 استخدام extension
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

  // ============================================================
  // 3) _buildIncomeAction – UI جديدة للدخل (بدون Exceptional)
  // ============================================================
  Widget _buildIncomeAction(BuildContext context, ResponsiveMetrics metrics) {
    final config = mode.config; // 👈 استخدام extension
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

  // ============================================================
  // 4) _buildTransferAction (مؤقتاً تعيد نفس الـ Expense)
  // ============================================================
  Widget _buildTransferAction(BuildContext context, ResponsiveMetrics metrics) {
    return _buildExpenseAction(context, metrics);
  }

  // ============================================================
  // 5) _submitEntry – منطق الحفظ المستخرج
  // ============================================================

  bool get _isExceptionalEnabled => mode == EntryMode.expense;

  Future<void> _submitEntry(BuildContext context) async {
    final result = await controller.submitEntry();

    // Handle simple validation errors
    if (!result.success) {
      switch (result.action) {
        case SaveAction.invalidAmount:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid amount')),
          );
          return;

        case SaveAction.noCategorySelected:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select category')),
          );
          return;

        case SaveAction.noAccountSelected:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select account')),
          );
          return;

        default:
          break;
      }
    }

    debugPrint(
      'SAVE RESULT => '
      'success=${result.success}, '
      'requiresConfirmation=${result.requiresConfirmation}, '
      'error=${result.errorMessage}, '
      'action=${result.action}',
    );

    if (result.requiresConfirmation) {
      debugPrint("OPENING CONFIRMATION DIALOG");

      final resolution = await showDialog<Resolution>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: const Text('Choose how you want to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint("BUTTON PRESSED");
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );

      debugPrint("DIALOG CLOSED");
      debugPrint("USER CHOICE = $resolution");

      return;
    }

    if (result.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
      return;
    }

    // Success
    if (result.success) {
      return;
    }
  }
}

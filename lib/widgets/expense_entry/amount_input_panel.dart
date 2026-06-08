// lib/widgets/expense_entry/amount_input_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import 'package:provider/provider.dart';
import '../../features/settings/controller/settings_controller.dart';
import '../../features/transactions/models/expense_resolution_analysis.dart';

class AmountInputPanel extends StatelessWidget {
  final TransactionEntryController controller;
  final VoidCallback? onAccountTap;

  const AmountInputPanel({
    super.key,
    required this.controller,
    this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isSmallScreen = metrics.width < 360;
    final double buttonSize = metrics.h(isKeyboardOpen ? 28 : 45);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(0),
        vertical: metrics.h(0),
      ),
      child: Container(
        padding: EdgeInsets.all(
          isSmallScreen ? metrics.spacing(6) : metrics.spacing(6),
        ),
        decoration: BoxDecoration(
          color: AppColors.inputPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.spacing(1),
                vertical: metrics.h(2),
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.spacing(12),
                        vertical: metrics.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                controller.amount,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: metrics.text(24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: metrics.spacing(8)),
                          Text(
                            controller.currentCurrency,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: metrics.text(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.spacing(4)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _topActionButton(metrics, Icons.note_alt_outlined),
                      SizedBox(width: metrics.spacing(6)),
                      _topActionButton(metrics, Icons.repeat),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: metrics.h(4)),
            _buildCalculator(context, metrics, buttonSize),
            SizedBox(height: metrics.h(3)),
            Row(
              children: [
                Expanded(
                  child: _infoButton(
                    metrics,
                    Icons.calendar_today_outlined,
                    'Today',
                  ),
                ),
                SizedBox(width: metrics.spacing(6)),
                Expanded(
                  child: _infoButton(
                    metrics,
                    Icons.account_balance_wallet_outlined,
                    controller.selectedAccountName,
                    onTap: onAccountTap,
                  ),
                ),
                SizedBox(width: metrics.spacing(6)),
                Expanded(
                  child: _infoButton(metrics, Icons.person_outline, 'Me'),
                ),
                SizedBox(width: metrics.spacing(6)),
                Expanded(
                  child: _infoButton(
                    metrics,
                    Icons.check_circle_outline,
                    'Done',
                  ),
                ),
              ],
            ),
            SizedBox(height: metrics.h(6)),
            Row(
              children: [
                Expanded(
                  child: _bottomActionButton(metrics, '', Icons.more_horiz),
                ),
                SizedBox(width: metrics.spacing(6)),
                Expanded(
                  flex: 2,
                  child: _addExceptionalButton(context, metrics),
                ),
                SizedBox(width: metrics.spacing(6)),
                Expanded(child: _bottomActionButton(metrics, '', Icons.mic)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculator(
    BuildContext context,
    ResponsiveMetrics metrics,
    double buttonSize,
  ) {
    final double rowSpacing = metrics.h(3);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _calcRow(context, metrics, buttonSize, ["1", "2", "3", "C"]),
        SizedBox(height: rowSpacing),
        _calcRow(context, metrics, buttonSize, ["4", "5", "6", "⌫"]),
        SizedBox(height: rowSpacing),
        _calcRow(context, metrics, buttonSize, ["7", "8", "9", "+"]),
        SizedBox(height: rowSpacing),
        _calcRow(context, metrics, buttonSize, [".", "0", "=", "x"]),
      ],
    );
  }

  Widget _calcRow(
    BuildContext context,
    ResponsiveMetrics metrics,
    double buttonSize,
    List<String> keys,
  ) {
    const operators = {"C", "⌫", "+", "x", ".", "="};
    const primary = {"="};
    return Row(
      children: keys.map((key) {
        return _calcButton(
          context,
          metrics,
          key,
          buttonSize,
          isOperator: operators.contains(key),
          isPrimary: primary.contains(key),
        );
      }).toList(),
    );
  }

  Widget _calcButton(
    BuildContext context,
    ResponsiveMetrics metrics,
    String text,
    double size, {
    bool isOperator = false,
    bool isPrimary = false,
  }) {
    final double fontSize = (size * 0.44).clamp(11.0, 22.0);
    return Expanded(
      child: SizedBox(
        height: size,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.spacing(2)),
          child: Material(
            color: isPrimary
                ? Colors.blue
                : isOperator
                ? AppColors.calculatorButton
                : AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.white24,
              highlightColor: Colors.white12,
              onTap: () {
                final settings = context.read<SettingsController>();
                if (settings.state.hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                controller.onCalculatorTap(text);
              },
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isPrimary
                        ? Colors.white
                        : isOperator
                        ? Colors.blue
                        : Colors.white,
                    fontSize: fontSize,
                    fontWeight: isOperator
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topActionButton(ResponsiveMetrics metrics, IconData icon) {
    final double buttonSize = metrics.h(50);
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: AppColors.calculatorButton,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: metrics.size(16)),
    );
  }

  Widget _infoButton(
    ResponsiveMetrics metrics,
    IconData icon,
    String text, {
    VoidCallback? onTap,
  }) {
    final isSmallScreen = metrics.width < 360;
    final double height = isSmallScreen ? metrics.h(38) : metrics.h(45);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.calculatorButton,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: metrics.size(15), color: Colors.white70),
            SizedBox(width: metrics.spacing(4)),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: metrics.text(11),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _addExceptionalButton(
    BuildContext context,
    ResponsiveMetrics metrics,
  ) {
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
                onTap: () async {
                  final result = await controller.validateAndSave(
                    isExceptional: controller.isExceptional,
                  );

                  if (!result.success) {
                    switch (result.action) {
                      case SaveAction.invalidAmount:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                          ),
                        );
                        return;

                      case SaveAction.noCategorySelected:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select category'),
                          ),
                        );
                        return;

                      case SaveAction.noAccountSelected:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select account'),
                          ),
                        );
                        return;

                      default:
                        break;
                    }
                  }

                  final analysis =
                      result.data?['analysis'] as ExpenseResolutionAnalysis?;

                  debugPrint('ACTION = ${result.action}');
                  debugPrint('ANALYSIS = $analysis');

                  if (analysis != null) {
                    debugPrint('SHORTAGE = ${analysis.shortage}');
                    debugPrint('LIQUIDITY = ${analysis.totalLiquidity}');
                    debugPrint('SAVINGS = ${analysis.totalSavings}');
                    debugPrint('RESERVED = ${analysis.totalReserved}');
                  }

                  if (!result.success &&
                      result.action == SaveAction.insufficientBalance) {
                    final shortage = result.data?['shortage'] ?? 0;

                    final action = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Insufficient Balance'),
                        content: Text('Shortage: $shortage'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'cancel'),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, 'temp_debt'),
                            child: const Text('Temp Debt'),
                          ),
                        ],
                      ),
                    );

                    if (action == 'temp_debt') {
                      final totalLiquidity = controller
                          .getTotalLiquidityBalance();
                      final expenseAmount =
                          double.tryParse(controller.amount) ?? 0;

                      debugPrint('TOTAL LIQUIDITY = $totalLiquidity');
                      debugPrint('EXPENSE AMOUNT = $expenseAmount');

                      if (totalLiquidity >= expenseAmount) {
                        await showDialog(
                          context: context,
                          builder: (_) => const AlertDialog(
                            title: Text('Temp Debt Blocked'),
                            content: Text(
                              'You already have enough money in other accounts.',
                            ),
                          ),
                        );
                        return;
                      }

                      await controller.addBalanceAndRetry(shortage);
                      debugPrint('TEMP DEBT BUTTON PRESSED');
                    }
                  }
                },
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add',
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
}

// lib/widgets/expense_entry/amount_input_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';
import 'package:provider/provider.dart';
import '../../features/settings/controller/settings_controller.dart';
import '../../services/sound_service.dart';
import 'entry_bottom_actions.dart'; // يحتوي على EntryBottomActions
import 'entry_context_row.dart'; // NEW import
import '../../features/transactions/models/entry_mode.dart';

class AmountInputPanel extends StatelessWidget {
  final TransactionEntryController controller;
  final VoidCallback? onAccountTap;
  final EntryMode mode;
  const AmountInputPanel({
    super.key,
    required this.controller,
    required this.mode,
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
            // 🔁 REPLACED WITH EntryContextRow
            EntryContextRow(
              controller: controller,
              metrics: metrics,
              mode: mode,
            ),
            SizedBox(height: metrics.h(6)),
            // 🔁 REPLACED WITH EntryBottomActions
            EntryBottomActions(
              controller: controller,
              metrics: metrics,
              mode: mode,
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

                SoundService.instance.playCalculatorTap();

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

  // _infoButton and _bottomActionButton and _addExceptionalButton( have been removed.
}

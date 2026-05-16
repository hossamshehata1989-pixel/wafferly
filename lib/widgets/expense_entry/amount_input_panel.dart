// lib/widgets/expense_entry/amount_input_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';

class AmountInputPanel extends StatelessWidget {
  final TransactionEntryController controller;

  const AmountInputPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    double buttonSize = screenHeight * 0.055;
    buttonSize = buttonSize.clamp(44.0, 62.0);

    if (keyboardHeight > 0) {
      buttonSize = buttonSize.clamp(40.0, 54.0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.currentCurrency,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      controller.amount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildCalculator(buttonSize),
        ],
      ),
    );
  }

  Widget _buildCalculator(double buttonSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _calcButton("1", buttonSize),
            const SizedBox(width: 4),
            _calcButton("2", buttonSize),
            const SizedBox(width: 4),
            _calcButton("3", buttonSize),
            const SizedBox(width: 4),
            _calcButton("C", buttonSize, isOperator: true),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _calcButton("4", buttonSize),
            const SizedBox(width: 4),
            _calcButton("5", buttonSize),
            const SizedBox(width: 4),
            _calcButton("6", buttonSize),
            const SizedBox(width: 4),
            _calcButton("⌫", buttonSize, isOperator: true),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _calcButton("7", buttonSize),
            const SizedBox(width: 4),
            _calcButton("8", buttonSize),
            const SizedBox(width: 4),
            _calcButton("9", buttonSize),
            const SizedBox(width: 4),
            _calcButton("+", buttonSize, isOperator: true),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _calcButton(".", buttonSize, isOperator: true),
            const SizedBox(width: 4),
            _calcButton("0", buttonSize),
            const SizedBox(width: 4),
            _calcButton("=", buttonSize, isOperator: true, isPrimary: true),
            const SizedBox(width: 4),
            _calcButton("", buttonSize, isDisabled: true, invisible: true),
          ],
        ),
      ],
    );
  }

  Widget _calcButton(
    String text,
    double size, {
    bool isOperator = false,
    bool isPrimary = false,
    bool isDisabled = false,
    bool invisible = false,
  }) {
    final double fontSize = (size * 0.4).clamp(16.0, 24.0);

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: isDisabled || invisible
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    controller.onCalculatorTap(text);
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: invisible
                    ? Colors.transparent
                    : isDisabled
                    ? Colors.transparent
                    : isPrimary
                    ? Colors.blue
                    : (isOperator
                          ? AppColors.cardSecondary
                          : AppColors.background),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: text.isEmpty
                  ? null
                  : Text(
                      text,
                      style: TextStyle(
                        color: isDisabled || invisible
                            ? Colors.transparent
                            : isPrimary
                            ? Colors.white
                            : (isOperator ? Colors.blue : Colors.white),
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
    );
  }
}

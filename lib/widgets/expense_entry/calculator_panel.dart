// lib/widgets/expense/calculator_panel.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CalculatorPanel extends StatelessWidget {
  final String amount;
  final String expression;
  final Function(String) onTap;

  const CalculatorPanel({
    super.key,
    required this.amount,
    required this.expression,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          Row(
            children: [
              _calcButton("1"),
              _calcButton("2"),
              _calcButton("3"),
              _calcButton("C", isOperator: true),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              _calcButton("4"),
              _calcButton("5"),
              _calcButton("6"),
              _calcButton("⌫", isOperator: true),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              _calcButton("7"),
              _calcButton("8"),
              _calcButton("9"),
              _calcButton("+", isOperator: true, isPrimary: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _calcButton(".", isOperator: true),
              _calcButton("0"),
              _calcButton("=", isOperator: true, isPrimary: true),
              const SizedBox(width: 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcButton(
    String text, {
    bool isOperator = false,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => onTap(text),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: isPrimary
                  ? Colors.blue
                  : (isOperator
                        ? AppColors.cardSecondary
                        : AppColors.background),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: isPrimary
                    ? Colors.white
                    : (isOperator ? Colors.blue : Colors.white),
                fontSize: 3,
                fontWeight: isOperator ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

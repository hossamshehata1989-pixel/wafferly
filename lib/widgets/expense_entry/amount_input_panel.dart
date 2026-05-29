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

    double buttonSize = screenHeight * 0.04;
    buttonSize = buttonSize.clamp(32.0, 42.0);

    if (keyboardHeight > 0) {
      buttonSize = buttonSize.clamp(34.0, 48.0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // Amount Display
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          controller.currentCurrency,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ), // Space between amount and action buttons

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _topActionButton(Icons.more_horiz), // More options button
                    const SizedBox(width: 6),

                    _topActionButton(Icons.note_alt_outlined), // Note button
                    const SizedBox(width: 6),

                    _topActionButton(Icons.check), // Confirm button
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          _buildCalculator(buttonSize),
        ],
      ),
    );
  }

  Widget _buildCalculator(double buttonSize) {
    // Calculator buttons
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _calcButton("1", buttonSize),
            const SizedBox(width: 1),
            _calcButton("2", buttonSize),
            const SizedBox(width: 1),
            _calcButton("3", buttonSize),
            const SizedBox(width: 1),
            _calcButton("C", buttonSize, isOperator: true),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            _calcButton("4", buttonSize),
            const SizedBox(width: 1),
            _calcButton("5", buttonSize),
            const SizedBox(width: 1),
            _calcButton("6", buttonSize),
            const SizedBox(width: 1),
            _calcButton("⌫", buttonSize, isOperator: true),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            _calcButton("7", buttonSize),
            const SizedBox(width: 1),
            _calcButton("8", buttonSize),
            const SizedBox(width: 1),
            _calcButton("9", buttonSize),
            const SizedBox(width: 1),
            _calcButton("+", buttonSize, isOperator: true),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            _calcButton(".", buttonSize, isOperator: true),
            const SizedBox(width: 1),
            _calcButton("0", buttonSize),
            const SizedBox(width: 1),
            _calcButton("=", buttonSize, isOperator: true, isPrimary: true),
            const SizedBox(width: 1),
            _calcButton("", buttonSize, isDisabled: true, invisible: true),
          ],
        ),
      ],
    );
  }

  Widget _topActionButton(IconData icon) {
    // Top right action buttons (note, more, confirm)
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _calcButton(
    // Calculator buttons
    String text,
    double size, {
    bool isOperator = false,
    bool isPrimary = false,
    bool isDisabled = false,
    bool invisible = false,
  }) {
    final double fontSize = (size * 0.4).clamp(
      16.0,
      24.0,
    ); // Dynamic font size based on button size

    return Expanded(
      // Each button takes equal horizontal space
      child: SizedBox(
        height: size,
        child: Padding(
          // Small padding around each button
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: isDisabled || invisible
                ? null
                : () {
                    HapticFeedback.lightImpact(); // Haptic feedback on button press
                    controller.onCalculatorTap(text);
                  },
            borderRadius: BorderRadius.circular(
              12,
            ), // Rounded corners for tap effect
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
              alignment: Alignment.center, // Center the text within the button
              child: text.isEmpty
                  ? null
                  : Text(
                      // Button text
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

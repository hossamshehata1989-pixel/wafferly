import 'package:flutter/material.dart';

class FinancialActionFooter extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback? onExecuteAll;

  const FinancialActionFooter({
    super.key,
    required this.onSkip,
    this.onExecuteAll,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12), // ✅ تقليل padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 40, // ✅ تقليل الارتفاع
              child: FilledButton(
                onPressed: onExecuteAll,
                style: FilledButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text("Execute All"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 36, // ✅ تقليل الارتفاع
              child: OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text("Skip For Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

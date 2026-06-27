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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onExecuteAll,
                child: const Text("Execute All"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSkip,
                child: const Text("Skip For Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

Future<bool?> showReleaseGoalDialog(
  BuildContext context, {
  required double totalAmount,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Release Goal'),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('All reserved money will be released.'),

          const SizedBox(height: 16),

          Text(
            '${totalAmount.toStringAsFixed(0)} EGP',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),

        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Release'),
        ),
      ],
    ),
  );
}

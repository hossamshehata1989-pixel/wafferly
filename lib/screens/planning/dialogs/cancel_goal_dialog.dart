import 'package:flutter/material.dart';

import '../../../models/goal_funding_source.dart';

Future<bool?> showCancelGoalDialog(
  BuildContext context, {
  required List<GoalFundingSource> fundingSources,
}) {
  final total = fundingSources.fold<double>(0, (sum, e) => sum + e.amount);

  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Cancel Goal'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('All reserved money will be released:'),

            const SizedBox(height: 16),

            ...fundingSources.map(
              (source) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(source.accountName)),
                    Text('${source.amount.toStringAsFixed(0)} EGP'),
                  ],
                ),
              ),
            ),

            const Divider(),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} EGP',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cancel Goal'),
        ),
      ],
    ),
  );
}

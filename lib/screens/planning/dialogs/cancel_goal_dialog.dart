import 'package:flutter/material.dart';
import '../../../models/goal_funding_source.dart';

/// Returns:
/// - 'keep'     -> keep reservations
/// - 'transfer' -> transfer reservations to saving
/// - 'release'  -> release reservations
/// - null       -> back/cancel
Future<String?> showCancelGoalDialog(
  BuildContext context, {
  required List<GoalFundingSource> fundingSources,
  bool archive = false,
  String? warningMessage,
}) {
  final total = fundingSources.fold<double>(0, (sum, e) => sum + e.amount);
  final title = archive ? 'Archive Goal' : 'Cancel Goal';
  final finalWord = archive ? 'archived' : 'cancelled';

  if (fundingSources.isEmpty) {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          warningMessage ??
              'There is no reserved money. This goal will be $finalWord.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: Text(archive ? 'Archive Goal' : 'Cancel Goal'),
          ),
        ],
      ),
    );
  }

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What would you like to do with the reserved money?',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            ...fundingSources.map(
              (source) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(source.accountName)),
                    Text('${source.amount.toStringAsFixed(0)} EGP'),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Reserved',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} EGP',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _archiveOption(
              context: context,
              icon: Icons.lock,
              color: Colors.green,
              title: 'Keep Reserved',
              description:
                  'Keep the reserved money locked.\nThe goal will be $finalWord.',
              result: 'keep',
            ),
            const SizedBox(height: 10),
            _archiveOption(
              context: context,
              icon: Icons.savings,
              color: Colors.purple,
              title: 'Transfer To Saving',
              description:
                  'Transfer the reserved money to saving.\nThe goal will be $finalWord.',
              result: 'transfer',
            ),
            const SizedBox(height: 10),
            _archiveOption(
              context: context,
              icon: Icons.lock_open,
              color: Colors.orange,
              title: 'Release',
              description:
                  'Release all reservations and return the money to available balance.\n'
                  'The goal will be $finalWord.',
              result: 'release',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
      ],
    ),
  );
}

Widget _archiveOption({
  required BuildContext context,
  required IconData icon,
  required Color color,
  required String title,
  required String description,
  required String result,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.pop(context, result),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

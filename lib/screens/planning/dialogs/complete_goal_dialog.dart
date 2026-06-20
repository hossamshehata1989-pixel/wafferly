// lib/screens/planning/dialogs/complete_goal_dialog.dart

import 'package:flutter/material.dart';

Future<String?> showCompleteGoalDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Goal Completed 🎉'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What would you like to do with the reserved money?',
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            _completionOption(
              context: context,
              icon: Icons.savings,
              color: Colors.purple,
              title: 'Transfer To Saving',
              description:
                  'Transfer all reserved funds to a saving account.\n'
                  'Goal will be archived.',
              result: 'transfer',
            ),

            const SizedBox(height: 12),

            _completionOption(
              context: context,
              icon: Icons.lock_open,
              color: Colors.orange,
              title: 'Release Money',
              description:
                  'Remove all reservations and return money to available balance.\n'
                  'Goal will be archived.',
              result: 'release',
            ),

            const SizedBox(height: 12),

            _completionOption(
              context: context,
              icon: Icons.lock,
              color: Colors.green,
              title: 'Keep Reserved',
              description:
                  'Keep reserved money locked.\n'
                  'You can release it later at any time.\n'
                  'Goal will be archived.',
              result: 'keep',
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

Widget _completionOption({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
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

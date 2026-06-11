import 'package:flutter/material.dart';

Future<String?> showCompleteGoalDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Goal Completed 🎉'),
      content: const Text('What would you like to do with the reserved money?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'saving'),
          child: const Text('Transfer To Saving'),
        ),

        TextButton(
          onPressed: () => Navigator.pop(context, 'release'),
          child: const Text('Release Money'),
        ),

        TextButton(
          onPressed: () => Navigator.pop(context, 'keep'),
          child: const Text('Keep Reserved'),
        ),
      ],
    ),
  );
}

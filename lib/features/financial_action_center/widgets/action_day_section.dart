import 'package:flutter/material.dart';

class ActionDaySection extends StatelessWidget {
  final String title;
  final int count;
  final Widget child;

  const ActionDaySection({
    super.key,
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6), // ✅ تقليل padding
          child: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 9,
                child: Text('$count', style: const TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

// lib/screens/planning/widgets/goal_progress_card.dart

import 'package:flutter/material.dart';
import '../../../models/enums/goal_type.dart';

class GoalProgressCard extends StatelessWidget {
  final String title;
  final double saved;
  final double target;
  final double progress;
  final GoalType type;

  const GoalProgressCard({
    super.key,
    required this.title,
    required this.saved,
    required this.target,
    required this.progress,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (target - saved).clamp(0.0, double.infinity);
    final percent = (progress * 100).toStringAsFixed(0);
    final isRecurring = type == GoalType.recurring;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRecurring
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isRecurring ? 'Recurring Goal' : 'Manual Goal',
                  style: TextStyle(
                    color: isRecurring ? Colors.blue : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saved', style: TextStyle(color: Colors.white70)),
              Text(
                '${saved.toStringAsFixed(0)} EGP',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target', style: TextStyle(color: Colors.white70)),
              Text(
                '${target.toStringAsFixed(0)} EGP',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remaining', style: TextStyle(color: Colors.white70)),
              Text(
                '${remaining.toStringAsFixed(0)} EGP',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            '$percent%',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

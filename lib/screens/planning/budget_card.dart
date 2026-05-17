import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final String icon;
  final String title;
  final double spent;
  final double total;
  final double progress;
  final bool bucketEnabled;

  const BudgetCard({
    super.key,
    required this.icon,
    required this.title,
    required this.spent,
    required this.total,
    required this.progress,
    required this.bucketEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text("$spent / $total"),

            const SizedBox(height: 8),

            LinearProgressIndicator(value: progress),

            const SizedBox(height: 10),

            CheckboxListTile(
              value: bucketEnabled,
              onChanged: (_) {},
              title: const Text("Create spending bucket"),
            ),
          ],
        ),
      ),
    );
  }
}

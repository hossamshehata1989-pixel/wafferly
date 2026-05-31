import 'package:flutter/material.dart';

class RecentTransactionsPreview extends StatelessWidget {
  const RecentTransactionsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A6B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.history, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Supermarket • 250 EGP',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Text('Today', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

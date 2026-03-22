// ==========================================
// 📦 Wafferly - Split Summary Card
// ==========================================

import 'package:flutter/material.dart';

class SplitSummaryCard extends StatelessWidget {
  final double recurringAmount;
  final double oneTimeAmount;

  const SplitSummaryCard({
    super.key,
    required this.recurringAmount,
    required this.oneTimeAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ==============================
        // 🟢 Recurring Card
        // ==============================
        Expanded(
          child: _SummaryCard(
            title: "Recurring",
            amount: recurringAmount,
            color: Colors.green,
            icon: Icons.repeat,
          ),
        ),

        const SizedBox(width: 12),

        // ==============================
        // 🔴 One-time Card
        // ==============================
        Expanded(
          child: _SummaryCard(
            title: "One-time",
            amount: oneTimeAmount,
            color: Colors.orange,
            icon: Icons.warning_rounded,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🔹 Internal Card Widget
// ==========================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        // 🎨 Dark Glass Effect
        color: Colors.white.withOpacity(0.05),

        border: Border.all(
          color: color.withOpacity(0.3),
        ),

        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==============================
          // 🔥 Icon + Title
          // ==============================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ==============================
          // 💰 Amount
          // ==============================
          Text(
            "${amount.toStringAsFixed(0)} EGP",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
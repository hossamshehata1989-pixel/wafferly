import 'package:flutter/material.dart';

class FinancialActionDisplay {
  final String title;

  final String subtitle;

  final String amount;

  final String actionLabel;

  final IconData icon;

  final String? accountName;

  final String? dueLabel;

  const FinancialActionDisplay({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.actionLabel,
    required this.icon,
    this.accountName,
    this.dueLabel,
  });
}

import 'package:flutter/material.dart';
import '../../../models/enums/scheduled_action_kind.dart';

class FinancialActionDisplay {
  final String title;
  final String subtitle;
  final String amountText;
  final String buttonText;
  final IconData icon;
  final String? sourceAccountName;
  final String? destinationAccountName;
  final DateTime dueDate;
  final ScheduledActionKind kind;
  final bool isGrouped;
  final int itemCount;
  final String? groupingSummary;

  const FinancialActionDisplay({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.buttonText,
    required this.icon,
    required this.dueDate,
    this.sourceAccountName,
    this.destinationAccountName,
    required this.kind,
    this.isGrouped = false,
    this.itemCount = 1,
    this.groupingSummary,
  });
}

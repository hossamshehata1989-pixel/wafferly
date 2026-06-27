import 'package:flutter/material.dart';

import '../../../models/scheduled_action_execution_context.dart';
import '../../../models/enums/scheduled_action_kind.dart';

import '../models/financial_action_display.dart';

class FinancialActionDisplayMapper {
  const FinancialActionDisplayMapper();

  FinancialActionDisplay fromContext(ScheduledActionExecutionContext context) {
    final action = context.action;

    return FinancialActionDisplay(
      title: action.title,
      subtitle: _subtitle(action.kind),
      amount: _formatAmount(action.amount),
      actionLabel: _button(action.kind),
      icon: _icon(action.kind),
      accountName: null,
      dueLabel: 'Due Today',
    );
  }

  String _subtitle(ScheduledActionKind kind) {
    switch (kind) {
      case ScheduledActionKind.expense:
        return 'Expense';
      case ScheduledActionKind.income:
        return 'Income';
      case ScheduledActionKind.goalContribution:
        return 'Goal Contribution';
      case ScheduledActionKind.transfer:
        return 'Transfer';
      case ScheduledActionKind.liabilityPayment:
        return 'Loan Payment';
      case ScheduledActionKind.budgetReset:
        return 'Budget Reset';
    }
  }

  String _button(ScheduledActionKind kind) {
    switch (kind) {
      case ScheduledActionKind.expense:
        return 'Pay';
      case ScheduledActionKind.income:
        return 'Receive';
      case ScheduledActionKind.goalContribution:
        return 'Save';
      case ScheduledActionKind.transfer:
        return 'Transfer';
      case ScheduledActionKind.liabilityPayment:
        return 'Pay';
      case ScheduledActionKind.budgetReset:
        return 'Reset';
    }
  }

  IconData _icon(ScheduledActionKind kind) {
    switch (kind) {
      case ScheduledActionKind.expense:
        return Icons.payments_outlined;
      case ScheduledActionKind.income:
        return Icons.south_west;
      case ScheduledActionKind.goalContribution:
        return Icons.flag_outlined;
      case ScheduledActionKind.transfer:
        return Icons.swap_horiz;
      case ScheduledActionKind.liabilityPayment:
        return Icons.credit_card;
      case ScheduledActionKind.budgetReset:
        return Icons.restart_alt;
    }
  }

  String _formatAmount(double amount) {
    return 'EGP ${amount.toStringAsFixed(0)}';
  }
}

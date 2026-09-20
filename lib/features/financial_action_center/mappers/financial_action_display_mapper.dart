import 'package:flutter/material.dart';

import '../../../models/scheduled_action_execution_context.dart';
import '../../../models/enums/scheduled_action_kind.dart';
import '../models/financial_action_display.dart';
import '../models/financial_action_projection_group.dart';

class FinancialActionDisplayMapper {
  const FinancialActionDisplayMapper();

  FinancialActionDisplay fromContext(ScheduledActionExecutionContext context) {
    final action = context.action;

    return FinancialActionDisplay(
      title: action.title,
      subtitle: _subtitle(action.kind),
      amountText: _formatAmount(action.amount),
      buttonText: _button(action.kind),
      icon: _icon(action.kind),
      sourceAccountName: action.sourceAccountId,
      destinationAccountName: action.destinationAccountId,
      dueDate: action.dueDate,
      kind: action.kind,
    );
  }

  FinancialActionDisplay fromProjectionGroup(
    FinancialActionProjectionGroup group,
  ) {
    final primary = group.primaryContext.action;

    return FinancialActionDisplay(
      title: group.title,
      subtitle: group.isGrouped
          ? '${group.count} scheduled payments'
          : _subtitle(group.kind),
      amountText: _formatAmount(group.totalAmount),
      buttonText: group.isGrouped ? 'Review' : _button(group.kind),
      icon: _icon(group.kind),
      sourceAccountName: primary.sourceAccountId,
      destinationAccountName: primary.destinationAccountId,
      dueDate: group.earliestDueDate,
      kind: group.kind,
      isGrouped: group.isGrouped,
      itemCount: group.count,
      groupingSummary: group.isGrouped ? group.summary : null,
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
      case ScheduledActionKind.investment:
        return 'Investment';
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
      case ScheduledActionKind.investment:
        return 'Invest';
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
      case ScheduledActionKind.investment:
        return Icons.trending_up;
    }
  }

  String _formatAmount(double amount) {
    return 'EGP ${amount.toStringAsFixed(0)}';
  }
}

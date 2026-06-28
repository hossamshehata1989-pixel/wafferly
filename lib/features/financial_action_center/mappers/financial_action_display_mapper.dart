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
      amountText: _formatAmount(action.amount),
      buttonText: _button(action.kind),
      icon: _icon(action.kind),
      sourceAccountName:
          action.sourceAccountId, // مؤقتاً، سيتم استبداله بالاسم الفعلي
      destinationAccountName: action.destinationAccountId,
      dueDate: action.dueDate,
      kind: action.kind,
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

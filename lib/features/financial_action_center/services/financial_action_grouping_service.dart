import '../../../models/scheduled_action_execution_context.dart';

import '../models/financial_action_day_group.dart';
import '../models/financial_action_group.dart';

class FinancialActionGroupingService {
  const FinancialActionGroupingService();

  List<FinancialActionDayGroup> group(
    List<ScheduledActionExecutionContext> actions, {
    DateTime? referenceDate,
  }) {
    final overdue = <ScheduledActionExecutionContext>[];
    final today = <ScheduledActionExecutionContext>[];
    final tomorrow = <ScheduledActionExecutionContext>[];
    final upcoming = <ScheduledActionExecutionContext>[];

    final now = _dateOnly(referenceDate ?? DateTime.now());

    for (final context in actions) {
      final due = _dateOnly(context.action.dueDate);

      if (due.isBefore(now)) {
        overdue.add(context);
      } else if (_isSameDay(due, now)) {
        today.add(context);
      } else if (_isSameDay(due, now.add(const Duration(days: 1)))) {
        tomorrow.add(context);
      } else {
        upcoming.add(context);
      }
    }

    return [
      _buildGroup(FinancialActionGroup.overdue, overdue),
      _buildGroup(FinancialActionGroup.today, today),
      _buildGroup(FinancialActionGroup.tomorrow, tomorrow),
      _buildGroup(FinancialActionGroup.upcoming, upcoming),
    ].whereType<FinancialActionDayGroup>().toList();
  }

  FinancialActionDayGroup? _buildGroup(
    FinancialActionGroup group,
    List<ScheduledActionExecutionContext> actions,
  ) {
    if (actions.isEmpty) return null;

    return FinancialActionDayGroup(group: group, actions: actions);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

import '../../../models/scheduled_action_execution_context.dart';

import '../models/financial_action_day_group.dart';
import '../models/financial_action_group.dart';
import '../models/financial_action_projection_group.dart';
import 'financial_action_projection_service.dart';

class FinancialActionGroupingService {
  const FinancialActionGroupingService();

  List<FinancialActionDayGroup> group(
    List<ScheduledActionExecutionContext> actions, {
    DateTime? referenceDate,
  }) {
    final projected = const FinancialActionProjectionService().project(
      actions,
      referenceDate: referenceDate,
    );

    final now = _dateOnly(referenceDate ?? DateTime.now());
    final overdue = <FinancialActionProjectionGroup>[];
    final today = <FinancialActionProjectionGroup>[];
    final tomorrow = <FinancialActionProjectionGroup>[];
    final upcoming = <FinancialActionProjectionGroup>[];

    for (final action in projected) {
      final due = _dateOnly(action.earliestDueDate);
      final target = due.isBefore(now)
          ? overdue
          : _isSameDay(due, now)
          ? today
          : _isSameDay(due, now.add(const Duration(days: 1)))
          ? tomorrow
          : upcoming;
      target.add(action);
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
    List<FinancialActionProjectionGroup> actions,
  ) {
    if (actions.isEmpty) return null;

    return FinancialActionDayGroup(
      group: group,
      actions: List.unmodifiable(actions),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

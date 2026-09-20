import '../../../models/enums/scheduled_action_kind.dart';
import '../../../models/scheduled_action_execution_context.dart';
import '../models/financial_action_projection_group.dart';

class FinancialActionProjectionService {
  const FinancialActionProjectionService();

  List<FinancialActionProjectionGroup> project(
    List<ScheduledActionExecutionContext> actions, {
    DateTime? referenceDate,
  }) {
    final now = _dateOnly(referenceDate ?? DateTime.now());
    final buckets = <String, List<ScheduledActionExecutionContext>>{};

    for (final context in actions) {
      final key = _keyFor(context);
      buckets.putIfAbsent(key, () => []).add(context);
    }

    final groups = buckets.entries.map((entry) {
      final contexts = [...entry.value]
        ..sort((a, b) => a.occurrence.dueDate.compareTo(b.occurrence.dueDate));

      var overdue = 0;
      var today = 0;
      var tomorrow = 0;
      var upcoming = 0;

      for (final context in contexts) {
        final due = _dateOnly(context.occurrence.dueDate);
        if (due.isBefore(now)) {
          overdue++;
        } else if (_isSameDay(due, now)) {
          today++;
        } else if (_isSameDay(due, now.add(const Duration(days: 1)))) {
          tomorrow++;
        } else {
          upcoming++;
        }
      }

      return FinancialActionProjectionGroup(
        key: entry.key,
        title: contexts.first.action.title,
        kind: contexts.first.action.kind,
        contexts: List.unmodifiable(contexts),
        earliestDueDate: contexts.first.occurrence.dueDate,
        overdueCount: overdue,
        todayCount: today,
        tomorrowCount: tomorrow,
        upcomingCount: upcoming,
      );
    }).toList();

    groups.sort((a, b) {
      final urgency = _urgency(a).compareTo(_urgency(b));
      if (urgency != 0) return urgency;
      return a.earliestDueDate.compareTo(b.earliestDueDate);
    });

    return List.unmodifiable(groups);
  }

  String _keyFor(ScheduledActionExecutionContext context) {
    final commitmentId = context.action.commitmentId;
    if (commitmentId != null && commitmentId.isNotEmpty) {
      return 'commitment:$commitmentId:${context.action.kind.name}';
    }

    return 'action:${context.action.id}';
  }

  int _urgency(FinancialActionProjectionGroup group) {
    if (group.overdueCount > 0) return 0;
    if (group.todayCount > 0) return 1;
    if (group.tomorrowCount > 0) return 2;
    return 3;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

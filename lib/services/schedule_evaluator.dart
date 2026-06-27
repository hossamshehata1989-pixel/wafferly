import '../models/enums/scheduled_action_state.dart';
import '../models/schedule_rule.dart';

class ScheduleEvaluator {
  const ScheduleEvaluator();

  ScheduledActionState evaluate({
    required ScheduleRule rule,
    required DateTime today,
  }) {
    final due = _dateOnly(rule.nextDueDate);
    final now = _dateOnly(today);

    if (now.isBefore(due)) {
      return ScheduledActionState.upcoming;
    }

    if (now.isAfter(due)) {
      return ScheduledActionState.overdue;
    }

    return ScheduledActionState.due;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

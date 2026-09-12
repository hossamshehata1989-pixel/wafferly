import 'commitment.dart';
import 'schedule_occurrence.dart';
import 'schedule_rule.dart';
import 'scheduled_action.dart';

class ScheduledActionExecutionContext {
  final ScheduledAction action;

  final Commitment commitment;

  final ScheduleRule scheduleRule;

  final ScheduleOccurrence occurrence;

  const ScheduledActionExecutionContext({
    required this.action,
    required this.commitment,
    required this.scheduleRule,
    required this.occurrence,
  });
}

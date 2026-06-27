import 'commitment.dart';
import 'schedule_rule.dart';
import 'scheduled_action.dart';

class ScheduledActionExecutionContext {
  final ScheduledAction action;

  final Commitment commitment;

  final ScheduleRule scheduleRule;

  const ScheduledActionExecutionContext({
    required this.action,
    required this.commitment,
    required this.scheduleRule,
  });
}

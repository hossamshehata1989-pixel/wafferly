import '../../../models/enums/scheduled_action_kind.dart';
import '../../../models/scheduled_action_execution_context.dart';

class FinancialActionProjectionGroup {
  final String key;
  final String title;
  final ScheduledActionKind kind;
  final List<ScheduledActionExecutionContext> contexts;
  final DateTime earliestDueDate;
  final int overdueCount;
  final int todayCount;
  final int tomorrowCount;
  final int upcomingCount;

  const FinancialActionProjectionGroup({
    required this.key,
    required this.title,
    required this.kind,
    required this.contexts,
    required this.earliestDueDate,
    required this.overdueCount,
    required this.todayCount,
    required this.tomorrowCount,
    required this.upcomingCount,
  });

  int get count => contexts.length;

  double get totalAmount =>
      contexts.fold(0, (sum, context) => sum + context.action.amount);

  ScheduledActionExecutionContext get primaryContext => contexts.first;

  bool get isGrouped => contexts.length > 1;

  String get summary {
    final parts = <String>[];
    if (overdueCount > 0) {
      parts.add('$overdueCount overdue');
    }
    if (todayCount > 0) {
      parts.add('$todayCount due today');
    }
    if (tomorrowCount > 0) {
      parts.add('$tomorrowCount due tomorrow');
    }
    if (upcomingCount > 0) {
      parts.add('$upcomingCount upcoming');
    }
    return parts.join(' • ');
  }
}

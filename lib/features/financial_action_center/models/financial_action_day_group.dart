import '../../../models/scheduled_action_execution_context.dart';
import 'financial_action_group.dart';

class FinancialActionDayGroup {
  final FinancialActionGroup group;

  final List<ScheduledActionExecutionContext> actions;

  const FinancialActionDayGroup({required this.group, required this.actions});
}

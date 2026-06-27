import '../../models/scheduled_action_execution_context.dart';

abstract class FinancialActionProvider {
  const FinancialActionProvider();

  Future<List<ScheduledActionExecutionContext>> getActions({
    required DateTime today,
  });
}

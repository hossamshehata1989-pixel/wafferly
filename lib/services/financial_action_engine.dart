import '../models/scheduled_action_execution_context.dart';
import '../models/enums/scheduled_action_state.dart';

import 'providers/financial_action_provider.dart';

class FinancialActionEngine {
  final List<FinancialActionProvider> providers;

  const FinancialActionEngine({required this.providers});

  Future<List<ScheduledActionExecutionContext>> getActions({
    required DateTime today,
  }) async {
    final List<ScheduledActionExecutionContext> actions = [];

    for (final provider in providers) {
      final result = await provider.getActions(today: today);

      actions.addAll(result);
    }

    actions.removeWhere(
      (context) => context.action.state == ScheduledActionState.upcoming,
    );

    actions.sort((a, b) => a.action.dueDate.compareTo(b.action.dueDate));

    return actions;
  }
}

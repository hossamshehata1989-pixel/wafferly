import '../mutations/goal_activity_mutation.dart';
import '../ports/goal_activity_port.dart';
import 'financial_mutation_handler.dart';

final class GoalActivityMutationHandler
    implements FinancialMutationHandler<GoalActivityMutation> {
  final GoalActivityPort _port;

  const GoalActivityMutationHandler({required GoalActivityPort port})
    : _port = port;

  @override
  Future<void> execute(GoalActivityMutation mutation) {
    return _port.recordActivity(mutation);
  }
}

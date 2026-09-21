import '../mutations/goal_activity_mutation.dart';
import '../ports/goal_activity_port.dart';
import 'financial_mutation_handler.dart';
import 'financial_transaction_context.dart';

final class GoalActivityMutationHandler
    implements FinancialMutationHandler<GoalActivityMutation> {
  final GoalActivityPort _port;

  const GoalActivityMutationHandler({
    required GoalActivityPort port,
  }) : _port = port;

  @override
  Future<void> execute(
    GoalActivityMutation mutation,
    FinancialTransactionContext context,
  ) {
    return _port.recordActivity(mutation, context);
  }
}
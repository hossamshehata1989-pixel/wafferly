import '../execution/financial_transaction_context.dart';
import '../mutations/goal_activity_mutation.dart';

abstract interface class GoalActivityPort {
  Future<void> recordActivity(
    GoalActivityMutation mutation,
    FinancialTransactionContext context,
  );
}
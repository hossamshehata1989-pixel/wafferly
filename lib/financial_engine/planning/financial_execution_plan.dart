import 'financial_mutation.dart';

final class FinancialExecutionPlan {
  final String planId;

  final String operationId;

  final String idempotencyKey;

  /// Ordered by the Planner.
  ///
  /// The Executor MUST preserve this order.
  final List<FinancialMutation> mutations;

  const FinancialExecutionPlan({
    required this.planId,
    required this.operationId,
    required this.idempotencyKey,
    required this.mutations,
  });
}

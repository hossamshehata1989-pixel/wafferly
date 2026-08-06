import '../planning_execution_context.dart';

/// ===============================================================
/// PlanningPolicy
/// ===============================================================
///
/// Policies may enrich or modify the execution context.
///
/// Unlike Guards:
/// - Guards validate.
/// - Policies decide execution behavior.
///
/// Policies must not mutate persistent state.
///
/// ===============================================================
abstract interface class PlanningPolicy {
  Future<PlanningExecutionContext> apply(PlanningExecutionContext context);
}

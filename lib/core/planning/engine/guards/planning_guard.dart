import '../planning_execution_context.dart';

/// ===============================================================
/// PlanningGuard
/// ===============================================================
///
/// Validates whether execution is allowed.
///
/// Guards protect invariants.
///
/// They DO NOT modify state.
///
/// ===============================================================
abstract interface class PlanningGuard {
  Future<void> validate(PlanningExecutionContext context);
}

import '../planner/planning_execution_plan.dart';

/// ===============================================================
/// PlanningIntegrityChecker
/// ===============================================================
///
/// Validates the final execution plan before execution.
///
/// This is the last validation stage before the Executor.
///
/// Unlike Guards:
/// - Guards validate business invariants.
///
/// Unlike Policies:
/// - Policies decide execution behavior.
///
/// Integrity checks the consistency of the final plan.
///
/// ===============================================================
abstract interface class PlanningIntegrityChecker {
  Future<void> validate(PlanningExecutionPlan plan);
}

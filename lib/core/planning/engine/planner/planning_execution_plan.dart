/// ===============================================================
/// PlanningExecutionPlan
/// ===============================================================
///
/// Immutable execution decision produced by the PlanningPlanner.
///
/// The Execution Plan does NOT contain execution logic.
///
/// It only describes HOW the operation should be executed.
///
/// ===============================================================
final class PlanningExecutionPlan {
  const PlanningExecutionPlan({required this.requiresUserApproval});

  /// Whether execution must be deferred until user approval.
  final bool requiresUserApproval;
}

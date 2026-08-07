import 'planning_mutation.dart';

/// ===============================================================
/// PlanningExecutionPlan
/// ===============================================================
///
/// Immutable execution recipe produced by the Planner.
///
/// ===============================================================
final class PlanningExecutionPlan {
  const PlanningExecutionPlan({
    required this.mutations,
    this.requiresUserApproval = false,
  });

  final List<PlanningMutation> mutations;

  final bool requiresUserApproval;
}

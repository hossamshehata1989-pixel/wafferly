import '../planner/planning_execution_plan.dart';

/// ===============================================================
/// PlanningExecutor
/// ===============================================================
///
/// Executes a validated PlanningExecutionPlan.
///
/// The Executor owns NO business rules.
///
/// It only applies PlanningMutations to the AllocationRepository.
///
/// ===============================================================
abstract interface class PlanningExecutor {
  Future<void> execute(PlanningExecutionPlan plan);
}

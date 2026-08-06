import '../planning_execution_context.dart';
import 'planning_execution_plan.dart';

/// ===============================================================
/// PlanningPlanner
/// ===============================================================
///
/// Produces an immutable execution plan.
///
/// ===============================================================
abstract interface class ExecutionPlanner {
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context);
}

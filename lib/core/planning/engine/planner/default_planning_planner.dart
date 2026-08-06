import '../planning_execution_context.dart';

import 'planning_execution_plan.dart';
import 'execution_planner.dart';

/// ===============================================================
/// DefaultPlanningPlanner
/// ===============================================================
final class DefaultPlanningPlanner implements ExecutionPlanner {
  const DefaultPlanningPlanner();

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    return const PlanningExecutionPlan(requiresUserApproval: false);
  }
}

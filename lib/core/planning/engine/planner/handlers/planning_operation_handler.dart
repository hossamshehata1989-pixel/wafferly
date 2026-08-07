import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';

abstract interface class PlanningOperationHandler {
  const PlanningOperationHandler();

  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context);
}

import 'financial_execution_plan.dart';
import 'planning_context.dart';

abstract interface class FinancialPlanner {
  Future<FinancialExecutionPlan> build(PlanningContext context);
}

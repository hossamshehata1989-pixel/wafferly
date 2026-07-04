import '../interpretation/normalized_intent.dart';
import 'financial_execution_plan.dart';

abstract interface class FinancialPlanner {
  Future<FinancialExecutionPlan> build(NormalizedIntent intent);
}

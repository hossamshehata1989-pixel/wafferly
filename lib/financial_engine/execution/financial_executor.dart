import '../planning/financial_execution_plan.dart';
import '../results/operation_result.dart';

abstract interface class FinancialExecutor {
  Future<OperationResult> execute(FinancialExecutionPlan plan);
}

import '../planning/financial_execution_plan.dart';
import '../results/operation_result.dart';
import 'financial_executor.dart';

final class MemoryFinancialExecutor implements FinancialExecutor {
  const MemoryFinancialExecutor();

  @override
  Future<OperationResult> execute(FinancialExecutionPlan plan) async {
    // TODO:
    // Execute mutations in memory.

    throw UnimplementedError();
  }
}

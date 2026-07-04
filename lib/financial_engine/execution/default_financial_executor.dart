import '../planning/financial_execution_plan.dart';
import '../results/operation_result.dart';
import 'financial_execution_summary.dart';
import 'financial_executor.dart';
import 'financial_unit_of_work.dart';
import 'mutation_handler_registry.dart';

final class DefaultFinancialExecutor implements FinancialExecutor {
  final MutationHandlerRegistry _registry;
  final FinancialUnitOfWork _unitOfWork;

  const DefaultFinancialExecutor({
    required MutationHandlerRegistry registry,
    required FinancialUnitOfWork unitOfWork,
  }) : _registry = registry,
       _unitOfWork = unitOfWork;

  @override
  Future<OperationResult> execute(FinancialExecutionPlan plan) async {
    try {
      await _unitOfWork.execute(() async {
        for (final mutation in plan.mutations) {
          final handler = _registry.handlerFor(mutation.runtimeType);

          await handler.execute(mutation);
        }
      });

      return const OperationSucceeded(
        summary: FinancialExecutionSummary(
          createdTransactionIds: [],
          balanceChanges: {},
          createdMutationIds: [],
        ),
      );
    } catch (error) {
      return OperationFailed(error: error);
    }
  }
}

import '../planning/financial_execution_plan.dart';
import '../mutations/create_transaction_mutation.dart';
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
  Future<OperationResult> execute(
    FinancialExecutionPlan plan,
  ) async {
    final createdTransactionIds = <String>[];

    try {
      await _unitOfWork.execute(
        (context) async {
          for (final mutation in plan.mutations) {
            final handler = _registry.handlerFor(
              mutation.runtimeType,
            );

            await handler.execute(
              mutation,
              context,
            );

            // The Executor is the authoritative bridge between planned
            // transaction mutations and the OperationResult.  Previously
            // this summary always returned an empty list, even though the
            // transaction had already been persisted successfully. That made
            // flows which need the freshly-created transaction identity
            // (e.g. Credit Card -> Installment conversion) believe the write
            // had no resolvable transaction.
            if (mutation is CreateTransactionMutation) {
              createdTransactionIds.add(mutation.record.transactionId);
            }
          }
        },
      );

      return OperationSucceeded(
        summary: FinancialExecutionSummary(
          createdTransactionIds: List.unmodifiable(createdTransactionIds),
          balanceChanges: const {},
          createdMutationIds: const [],
        ),
      );
    } catch (error) {
      return OperationFailed(error: error);
    }
  }
}

import '../../entities/allocation.dart';
import '../../operations/reserve_operation.dart';
import '../../ports/allocation_repository.dart';
import '../../value_objects/allocation_status.dart';
import 'planning_executor.dart';
import '../planning_execution_context.dart';

/// ===============================================================
/// DefaultPlanningExecutor
/// ===============================================================
///
/// Default implementation of the PlanningExecutor.
///
/// Executes validated PlanningOperations.
///
/// Currently supported:
/// - ReserveOperation
///
/// ===============================================================
final class DefaultPlanningExecutor implements PlanningExecutor {
  const DefaultPlanningExecutor({required this.repository});

  final AllocationRepository repository;

  @override
  Future<void> execute(PlanningExecutionContext context) async {
    final operation = context.operation;

    switch (operation) {
      case ReserveOperation():
        // Build the operational Allocation state
        // from the immutable PlanningOperation.
        final Allocation allocation = Allocation(
          // TODO(Architecture):
          // Replace with unified IdentityProvider after the global identity strategy
          // is introduced for Wafferly.
          id: operation.id,
          sourceId: operation.sourceId,
          sourceType: operation.sourceType,
          accountId: operation.accountId,
          amount: operation.amount,
          status: AllocationStatus.active,
          createdAt: operation.createdAt,
        );

        await repository.create(allocation);

        break;
    }
  }
}

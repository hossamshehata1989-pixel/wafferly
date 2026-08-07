import '../../entities/allocation.dart';
import '../../ports/allocation_id_generator.dart';
import '../../ports/allocation_repository.dart';
import '../../value_objects/allocation_status.dart';
import '../planner/planning_execution_plan.dart';
import '../planner/planning_mutation.dart';
import 'planning_executor.dart';

final class DefaultPlanningExecutor implements PlanningExecutor {
  const DefaultPlanningExecutor({
    required this.repository,
    required this.idGenerator,
  });

  final AllocationRepository repository;
  final AllocationIdGenerator idGenerator;

  @override
  Future<void> execute(PlanningExecutionPlan plan) async {
    for (final mutation in plan.mutations) {
      switch (mutation) {
        case CreateAllocationMutation():
          await repository.create(
            Allocation(
              id: mutation.allocationId,
              sourceId: mutation.sourceId,
              sourceType: mutation.sourceType,
              accountId: mutation.accountId,
              amount: mutation.amount,
              status: AllocationStatus.active,
              createdAt: mutation.createdAt,
            ),
          );

        case IncreaseAllocationMutation():
          final allocation = await repository.findById(mutation.allocationId);

          if (allocation == null) {
            throw StateError('Allocation not found.');
          }

          await repository.update(
            allocation.copyWith(
              amount: allocation.amount + mutation.amount,
              version: allocation.version + 1,
              updatedAt: DateTime.now(),
            ),
          );

        case DecreaseAllocationMutation():
          final allocation = await repository.findById(mutation.allocationId);

          if (allocation == null) {
            throw StateError('Allocation not found.');
          }

          await repository.update(
            allocation.copyWith(
              amount: allocation.amount - mutation.amount,
              version: allocation.version + 1,
              updatedAt: DateTime.now(),
            ),
          );
      }
    }
  }
}

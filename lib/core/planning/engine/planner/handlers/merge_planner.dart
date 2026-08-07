import '../../../operations/merge_operation.dart';
import '../../../ports/allocation_repository.dart';

import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';
import '../planning_mutation.dart';
import 'planning_operation_handler.dart';

final class MergePlanner implements PlanningOperationHandler {
  const MergePlanner({required this.repository});

  final AllocationRepository repository;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    final operation = context.operation as MergeOperation;

    final sourceAllocation = await repository.findActiveBySource(
      operation.source.id,
    );

    if (sourceAllocation == null) {
      throw StateError('Source allocation not found.');
    }

    final targetAllocation = await repository.findActiveBySource(
      operation.target.id,
    );

    if (targetAllocation == null) {
      throw StateError('Target allocation not found.');
    }

    return PlanningExecutionPlan(
      mutations: [
        IncreaseAllocationMutation(
          allocationId: targetAllocation.id,
          amount: sourceAllocation.amount,
        ),
        DeactivateAllocationMutation(allocationId: sourceAllocation.id),
      ],
    );
  }
}

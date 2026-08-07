import '../../../operations/reallocate_operation.dart';
import '../../../ports/allocation_repository.dart';

import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';
import '../planning_mutation.dart';
import 'planning_operation_handler.dart';

final class ReallocatePlanner implements PlanningOperationHandler {
  const ReallocatePlanner({required this.repository});

  final AllocationRepository repository;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    final operation = context.operation as ReallocateOperation;

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

    if (operation.amount >= sourceAllocation.amount) {
      throw StateError(
        'Reallocation amount must be less than the source allocation.',
      );
    }

    return PlanningExecutionPlan(
      mutations: [
        DecreaseAllocationMutation(
          allocationId: sourceAllocation.id,
          amount: operation.amount,
        ),
        IncreaseAllocationMutation(
          allocationId: targetAllocation.id,
          amount: operation.amount,
        ),
      ],
    );
  }
}

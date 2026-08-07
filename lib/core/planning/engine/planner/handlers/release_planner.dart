import '../../../operations/release_operation.dart';
import '../../../ports/allocation_repository.dart';

import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';
import '../planning_mutation.dart';
import 'planning_operation_handler.dart';

final class ReleasePlanner implements PlanningOperationHandler {
  const ReleasePlanner({required this.repository});

  final AllocationRepository repository;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    final operation = context.operation as ReleaseOperation;

    final allocation = await repository.findActiveBySource(operation.sourceId);

    if (allocation == null) {
      throw StateError('No allocation found for planning source.');
    }

    return PlanningExecutionPlan(
      mutations: [
        DecreaseAllocationMutation(
          allocationId: allocation.id,
          amount: operation.amount,
        ),
      ],
    );
  }
}

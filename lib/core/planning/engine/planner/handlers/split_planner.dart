import '../../../operations/split_operation.dart';
import '../../../ports/allocation_id_generator.dart';
import '../../../ports/allocation_repository.dart';

import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';
import '../planning_mutation.dart';
import 'planning_operation_handler.dart';

final class SplitPlanner implements PlanningOperationHandler {
  const SplitPlanner({required this.repository, required this.idGenerator});

  final AllocationRepository repository;
  final AllocationIdGenerator idGenerator;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    final operation = context.operation as SplitOperation;

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
      return PlanningExecutionPlan(
        mutations: [
          DecreaseAllocationMutation(
            allocationId: sourceAllocation.id,
            amount: operation.amount,
          ),
          CreateAllocationMutation(
            allocationId: idGenerator.next(),
            createdAt: operation.createdAt,
            sourceId: operation.target.id,
            sourceType: operation.target.type,
            accountId: operation.accountId,
            amount: operation.amount,
          ),
        ],
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

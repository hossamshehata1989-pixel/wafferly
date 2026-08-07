import '../../operations/release_operation.dart';
import '../../operations/reserve_operation.dart';
import '../../operations/split_operation.dart';

import '../../ports/allocation_repository.dart';

import '../planning_execution_context.dart';

import 'execution_planner.dart';
import 'planning_execution_plan.dart';
import 'planning_mutation.dart';
import '../../ports/allocation_id_generator.dart';

final class DefaultPlanningPlanner implements ExecutionPlanner {
  const DefaultPlanningPlanner({
    required this.repository,
    required this.idGenerator,
  });

  final AllocationRepository repository;

  final AllocationIdGenerator idGenerator;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    switch (context.operation) {
      case ReserveOperation operation:
        return PlanningExecutionPlan(
          mutations: [
            CreateAllocationMutation(
              allocationId: idGenerator.next(),
              createdAt: operation.createdAt,
              sourceId: operation.sourceId,
              sourceType: operation.sourceType,
              accountId: operation.accountId,
              amount: operation.amount,
            ),
          ],
        );

      case ReleaseOperation operation:
        final allocation = await repository.findActiveBySource(
          operation.sourceId,
        );

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

      case SplitOperation operation:
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

    throw UnsupportedError(
      'Unsupported planning operation: ${context.operation.runtimeType}',
    );
  }
}

import '../../../operations/release_operation.dart';
import '../../../ports/allocation_repository.dart';
import '../../../value_objects/allocation_status.dart';

import '../../planning_execution_context.dart';
import '../planning_execution_plan.dart';
import '../planning_mutation.dart';
import 'planning_operation_handler.dart';

/// ===============================================================
/// ReleasePlanner
/// ===============================================================
///
/// Plans the release of reserved money from a Planning Source.
///
/// A Planning Source may own multiple Allocations for the same account.
/// Release therefore consumes active allocations in FIFO order.
///
/// Rules:
/// - Only active allocations participate.
/// - Only allocations belonging to the requested account participate.
/// - Partial release keeps the Allocation identity.
/// - Full consumption deactivates/releases the Allocation.
/// - No Allocation is mutated here.
/// - The Planner only produces mutations.
/// ===============================================================

final class ReleasePlanner implements PlanningOperationHandler {
  const ReleasePlanner({required this.repository});

  final AllocationRepository repository;

  @override
  Future<PlanningExecutionPlan> plan(PlanningExecutionContext context) async {
    final operation = context.operation as ReleaseOperation;

    final allocations = await repository.findBySource(operation.sourceId);

    final candidates =
        allocations
            .where(
              (allocation) =>
                  allocation.status == AllocationStatus.active &&
                  allocation.accountId == operation.accountId &&
                  allocation.amount > 0,
            )
            .toList()
          ..sort((a, b) {
            final createdAtComparison = a.createdAt.compareTo(b.createdAt);

            if (createdAtComparison != 0) {
              return createdAtComparison;
            }

            // Deterministic tie-breaker.
            return a.id.compareTo(b.id);
          });

    if (candidates.isEmpty) {
      throw StateError(
        'No active allocation found for planning source '
        '${operation.sourceId} and account ${operation.accountId}.',
      );
    }

    var remaining = operation.amount;

    final mutations = <PlanningMutation>[];

    for (final allocation in candidates) {
      if (remaining <= 0) {
        break;
      }

      final allocationAmount = allocation.amount;

      if (remaining < allocationAmount) {
        // Partial release.
        mutations.add(
          DecreaseAllocationMutation(
            allocationId: allocation.id,
            amount: remaining,
          ),
        );

        remaining = 0;
        break;
      }

      // Full consumption of this Allocation.
      mutations.add(DeactivateAllocationMutation(allocationId: allocation.id));

      remaining -= allocationAmount;
    }

    if (remaining > 0) {
      throw StateError(
        'Insufficient allocation amount. '
        '$remaining remains after consuming all active allocations.',
      );
    }

    return PlanningExecutionPlan(mutations: mutations);
  }
}

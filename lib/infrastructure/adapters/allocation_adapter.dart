import '../../core/money/money.dart';
import '../../core/planning/engine/planning_engine.dart';
import '../../core/planning/entities/allocation.dart';
import '../../core/planning/operations/release_operation.dart';
import '../../core/planning/operations/restore_allocations_operation.dart';
import '../../core/planning/ports/allocation_repository.dart';
import '../../core/planning/value_objects/allocation_status.dart';
import '../../core/planning/value_objects/planning_source_type.dart';
import '../../financial_engine/execution/financial_transaction_context.dart';
import '../../financial_engine/mutations/release_allocation_mutation.dart';
import '../../financial_engine/ports/allocation_port.dart';

final class AllocationAdapter implements AllocationPort {
  final PlanningEngine planningEngine;
  final AllocationRepository allocationRepository;

  const AllocationAdapter({
    required this.planningEngine,
    required this.allocationRepository,
  });

  @override
  Future<void> releaseAllocation(
    ReleaseAllocationMutation mutation,
    FinancialTransactionContext context,
  ) async {
    final allocations = await allocationRepository.findBySource(
      mutation.goalId,
    );

    final affectedAllocations = allocations
        .where(
          (allocation) =>
              allocation.accountId == mutation.accountId &&
              allocation.status == AllocationStatus.active &&
              allocation.amount > Money.zero,
        )
        .toList();

    if (affectedAllocations.isEmpty) {
      throw StateError(
        'No active allocation found for goal '
        '${mutation.goalId} and account ${mutation.accountId}.',
      );
    }

    final snapshots = List<Allocation>.unmodifiable(
      affectedAllocations,
    );

    context.registerRollback(() async {
      await planningEngine.execute(
        RestoreAllocationsOperation(
          id:
              'restore-release-${mutation.goalId}-${mutation.accountId}-${mutation.amount}',
          createdAt: DateTime.now(),
          snapshots: snapshots,
        ),
      );
    });

    final operation = ReleaseOperation(
      id: 'release-${mutation.goalId}-${mutation.accountId}-${mutation.amount}',
      createdAt: DateTime.now(),
      sourceId: mutation.goalId,
      sourceType: PlanningSourceType.goal,
      accountId: mutation.accountId,
      amount: mutation.amount,
    );

    await planningEngine.execute(operation);
  }
}
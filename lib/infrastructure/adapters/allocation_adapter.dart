import '../../core/planning/engine/planning_engine.dart';
import '../../core/planning/operations/release_operation.dart';
import '../../core/planning/value_objects/planning_source_type.dart';
import '../../financial_engine/mutations/release_allocation_mutation.dart';
import '../../financial_engine/ports/allocation_port.dart';

final class AllocationAdapter implements AllocationPort {
  final PlanningEngine planningEngine;

  const AllocationAdapter({required this.planningEngine});

  @override
  Future<void> releaseAllocation(ReleaseAllocationMutation mutation) {
    final operation = ReleaseOperation(
      id: 'release-${mutation.goalId}-${mutation.accountId}-${mutation.amount}',
      createdAt: DateTime.now(),
      sourceId: mutation.goalId,
      sourceType: PlanningSourceType.goal,
      accountId: mutation.accountId,
      amount: mutation.amount,
    );

    return planningEngine.execute(operation);
  }
}

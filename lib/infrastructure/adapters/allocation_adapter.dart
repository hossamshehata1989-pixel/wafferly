import '../../financial_engine/mutations/release_allocation_mutation.dart';
import '../../financial_engine/ports/allocation_port.dart';
import '../../services/goal_allocation_service.dart';

final class AllocationAdapter implements AllocationPort {
  final GoalAllocationService service;

  const AllocationAdapter({required this.service});

  @override
  Future<void> releaseAllocation(ReleaseAllocationMutation mutation) {
    return service.reduceAllocation(
      goalId: mutation.goalId,
      accountId: mutation.accountId,
      reductionAmount: mutation.amount,
    );
  }
}

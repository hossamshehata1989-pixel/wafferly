import '../../services/goal_allocation_service.dart';
import '../planning/release_allocation_mutation.dart';
import 'financial_mutation_handler.dart';

final class ReleaseAllocationMutationHandler
    implements FinancialMutationHandler<ReleaseAllocationMutation> {
  final GoalAllocationService _service;

  const ReleaseAllocationMutationHandler({
    required GoalAllocationService service,
  }) : _service = service;

  @override
  Future<void> execute(ReleaseAllocationMutation mutation) async {
    await _service.reduceAllocation(
      goalId: mutation.goalId,
      accountId: mutation.accountId,
      reductionAmount: mutation.amount,
    );
  }
}

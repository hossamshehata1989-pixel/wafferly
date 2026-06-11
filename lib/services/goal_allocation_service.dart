import 'package:uuid/uuid.dart';

import '../models/allocation.dart';
import '../models/enums/allocation_type.dart';
import 'allocation_service.dart';
import 'allocation_validator.dart';

class GoalAllocationService {
  final AllocationService _allocationService = AllocationService();
  final AllocationValidator _validator = AllocationValidator();

  Future<bool> createAllocation({
    required String accountId,
    required String goalId,
    required double amount,
  }) async {
    final canAllocate = _validator.canAllocate(
      accountId: accountId,
      amount: amount,
    );

    if (!canAllocate) {
      return false;
    }

    final allocation = Allocation(
      id: const Uuid().v4(),
      accountId: accountId,
      amount: amount,
      type: AllocationType.goal,
      referenceId: goalId,
      createdAt: DateTime.now(),
    );

    await _allocationService.add(allocation);

    return true;
  }

  Future<void> releaseGoal(String goalId) async {
    final allocations = _allocationService
        .getAll()
        .where((a) => a.type == AllocationType.goal && a.referenceId == goalId)
        .toList();

    for (final allocation in allocations) {
      await _allocationService.delete(allocation.id);
    }
  }
}

// lib/services/goal_allocation_service.dart

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

  /// Release all goal allocations (full release)
  Future<void> releaseGoal(String goalId) async {
    final allocations = _allocationService
        .getAll()
        .where((a) => a.type == AllocationType.goal && a.referenceId == goalId)
        .toList();

    for (final allocation in allocations) {
      await _allocationService.delete(allocation.id);
    }
  }

  /// Reduce allocations for a specific goal and account by the given amount.
  /// Supports multiple allocations and consumes them cumulatively (FIFO order).
  Future<void> reduceAllocation({
    required String goalId,
    required String accountId,
    required double reductionAmount,
  }) async {
    if (reductionAmount <= 0) {
      throw Exception('Reduction amount must be greater than zero');
    }

    // Get all allocations for this goal and account
    final allocations = _allocationService
        .getAll()
        .where(
          (a) =>
              a.type == AllocationType.goal &&
              a.referenceId == goalId &&
              a.accountId == accountId,
        )
        .toList();

    if (allocations.isEmpty) {
      throw Exception(
        'No allocation found for goal $goalId and account $accountId',
      );
    }

    // Sort by creation date (oldest first) to maintain FIFO order
    allocations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double remaining = reductionAmount;

    for (final allocation in allocations) {
      if (remaining <= 0) break;

      final currentAmount = allocation.amount;

      if (currentAmount <= remaining) {
        // Full allocation consumed — delete it
        await _allocationService.delete(allocation.id);
        remaining -= currentAmount;
      } else {
        // Partial consumption — update allocation amount
        final newAmount = currentAmount - remaining;
        final updated = allocation.copyWith(amount: newAmount);
        await _allocationService.update(updated);
        remaining = 0;
      }
    }

    if (remaining > 0) {
      throw Exception(
        'Insufficient allocation amount. $remaining EGP remains after consuming all allocations.',
      );
    }
  }

  /// Increase allocations for a specific goal and account by the given amount.
  /// Used for rollback operations.
  Future<void> increaseAllocation({
    required String goalId,
    required String accountId,
    required double increaseAmount,
  }) async {
    if (increaseAmount <= 0) {
      throw Exception('Increase amount must be greater than zero');
    }

    // Get existing allocations for this goal and account
    final allocations = _allocationService
        .getAll()
        .where(
          (a) =>
              a.type == AllocationType.goal &&
              a.referenceId == goalId &&
              a.accountId == accountId,
        )
        .toList();

    if (allocations.isEmpty) {
      // If no allocation exists, create a new one
      final newAllocation = Allocation.create(
        accountId: accountId,
        amount: increaseAmount,
        type: AllocationType.goal,
        referenceId: goalId,
      );
      await _allocationService.add(newAllocation);
      return;
    }

    // Add the amount to the first allocation (FIFO — simple approach)
    final allocation = allocations.first;
    final updated = allocation.copyWith(
      amount: allocation.amount + increaseAmount,
    );
    await _allocationService.update(updated);
  }

  /// Get all allocations for a specific goal
  List<Allocation> getGoalAllocations(String goalId) {
    return _allocationService
        .getAll()
        .where((a) => a.type == AllocationType.goal && a.referenceId == goalId)
        .toList();
  }

  Future<void> releaseFundingSource({
    required String goalId,
    required String accountId,
  }) async {
    final allocations = _allocationService
        .getAll()
        .where(
          (a) =>
              a.type == AllocationType.goal &&
              a.referenceId == goalId &&
              a.accountId == accountId,
        )
        .toList();

    for (final allocation in allocations) {
      await _allocationService.delete(allocation.id);
    }
  }
}

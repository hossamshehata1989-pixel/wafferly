// lib/services/goal_allocation_service.dart

import 'package:uuid/uuid.dart';
import '../models/allocation.dart';
import '../models/enums/allocation_type.dart';
import 'allocation_service.dart';
import 'allocation_validator.dart';
import 'goal_funding_projection_service.dart';
import 'goal_service.dart';
import '../core/planning/engine/planning_engine.dart';

class GoalAllocationService {
  GoalAllocationService({required PlanningEngine engine}) : _engine = engine;

  final PlanningEngine _engine;

  final AllocationService _allocationService = AllocationService();
  final AllocationValidator _validator = AllocationValidator();
  final GoalService _goalService = GoalService();
  final GoalFundingProjectionService _projectionService =
      GoalFundingProjectionService();

  /// Creates a new goal allocation if:
  /// - The account has enough available balance.
  /// - The new allocation does not exceed the goal target.
  Future<bool> createAllocation({
    required String accountId,
    required String goalId,
    required double amount,
  }) async {
    // 1️⃣ التحقق من الرصيد المتاح
    final canAllocate = _validator.canAllocate(
      accountId: accountId,
      amount: amount,
    );
    if (!canAllocate) {
      return false;
    }

    // 2️⃣ التحقق من عدم تجاوز الهدف (الحماية الأساسية)
    final goal = _goalService.getById(goalId);
    if (goal == null) {
      return false;
    }

    final projection = _projectionService.getProjection(goalId);
    final currentProgress = projection.totalProgress; // Reserved + Saved

    final newProgress = currentProgress + amount;

    if (newProgress > goal.targetAmount) {
      // ❌ رفض العملية – لا يتم إنشاء Allocation
      return false;
    }

    // 3️⃣ إنشاء Allocation
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

    // ✅ الحفاظ على FIFO order (مثل reduceAllocation)
    allocations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

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

  /// Release all allocations for a specific funding source (account) within a goal
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

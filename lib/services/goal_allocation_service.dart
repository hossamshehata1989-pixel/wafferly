import 'package:uuid/uuid.dart';

import '../core/planning/engine/planning_engine.dart';
import '../core/planning/operations/reserve_operation.dart';
import '../core/planning/value_objects/planning_source_type.dart';

import '../models/allocation.dart';
import '../models/enums/allocation_type.dart';
import 'allocation_service.dart';
import 'goal_funding_projection_service.dart';
import 'goal_service.dart';

class GoalAllocationService {
  GoalAllocationService({
    required PlanningEngine engine,
    required GoalFundingProjectionService projectionService,
  }) : _engine = engine,
       _projectionService = projectionService;

  final PlanningEngine _engine;

  final AllocationService _allocationService = AllocationService();
  final GoalService _goalService = GoalService();
  final GoalFundingProjectionService _projectionService;

  Future<bool> createAllocation({
    required String accountId,
    required String goalId,
    required double amount,
  }) async {
    if (amount <= 0) {
      return false;
    }

    // ---------------------------------------------------------------
    // STEP 1 — Validate Goal
    // ---------------------------------------------------------------

    final goal = _goalService.getById(goalId);

    if (goal == null) {
      return false;
    }

    // ---------------------------------------------------------------
    // STEP 2 — Validate Goal Target
    // ---------------------------------------------------------------
    //
    // Goal business rule remains here.
    // Planning does not know about Goal target semantics.
    //
    // ---------------------------------------------------------------

    final projection = await _projectionService.getProjection(goalId);

    final currentProgress = projection.totalProgress;
    final newProgress = currentProgress + amount;

    if (newProgress > goal.targetAmount) {
      return false;
    }

    // ---------------------------------------------------------------
    // STEP 3 — Create Planning Operation
    // ---------------------------------------------------------------

    final operation = ReserveOperation(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      sourceId: goalId,
      sourceType: PlanningSourceType.goal,
      accountId: accountId,
      amount: amount,
    );

    // ---------------------------------------------------------------
    // STEP 4 — Planning Engine owns the mutation
    // ---------------------------------------------------------------

    try {
      await _engine.execute(operation);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===============================================================
  // LEGACY OPERATIONS
  // ===============================================================
  //
  // These remain temporarily until their corresponding Planning
  // operations are migrated and tested.
  //
  // ===============================================================

  /// Release all goal allocations.
  ///
  /// TEMPORARY LEGACY PATH.
  Future<void> releaseGoal(String goalId) async {
    final allocations = _allocationService
        .getAll()
        .where((a) => a.type == AllocationType.goal && a.referenceId == goalId)
        .toList();

    for (final allocation in allocations) {
      await _allocationService.delete(allocation.id);
    }
  }

  /// Reduce allocations for a specific goal/account.
  ///
  /// TEMPORARY LEGACY PATH.
  Future<void> reduceAllocation({
    required String goalId,
    required String accountId,
    required double reductionAmount,
  }) async {
    if (reductionAmount <= 0) {
      throw Exception('Reduction amount must be greater than zero');
    }

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

    allocations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double remaining = reductionAmount;

    for (final allocation in allocations) {
      if (remaining <= 0) {
        break;
      }

      final currentAmount = allocation.amount;

      if (currentAmount <= remaining) {
        await _allocationService.delete(allocation.id);
        remaining -= currentAmount;
      } else {
        final newAmount = currentAmount - remaining;

        final updated = allocation.copyWith(amount: newAmount);

        await _allocationService.update(updated);
        remaining = 0;
      }
    }

    if (remaining > 0) {
      throw Exception(
        'Insufficient allocation amount. '
        '$remaining EGP remains after consuming all allocations.',
      );
    }
  }

  /// Increase allocation.
  ///
  /// TEMPORARY LEGACY PATH.
  Future<void> increaseAllocation({
    required String goalId,
    required String accountId,
    required double increaseAmount,
  }) async {
    if (increaseAmount <= 0) {
      throw Exception('Increase amount must be greater than zero');
    }

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
      final newAllocation = Allocation.create(
        accountId: accountId,
        amount: increaseAmount,
        type: AllocationType.goal,
        referenceId: goalId,
      );

      await _allocationService.add(newAllocation);
      return;
    }

    allocations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final allocation = allocations.first;

    final updated = allocation.copyWith(
      amount: allocation.amount + increaseAmount,
    );

    await _allocationService.update(updated);
  }

  /// Get all allocations for a Goal.
  ///
  /// TEMPORARY LEGACY PATH.
  List getGoalAllocations(String goalId) {
    return _allocationService
        .getAll()
        .where((a) => a.type == AllocationType.goal && a.referenceId == goalId)
        .toList();
  }

  /// Release all allocations from one funding account.
  ///
  /// TEMPORARY LEGACY PATH.
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

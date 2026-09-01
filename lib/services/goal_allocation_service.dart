import 'package:uuid/uuid.dart';

import '../core/planning/engine/planning_engine.dart';
import '../core/planning/operations/reserve_operation.dart';
import '../core/planning/operations/release_operation.dart';
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
    if (amount <= 0) return false;

    final goal = _goalService.getById(goalId);
    if (goal == null || goal.targetAmount <= 0) return false;

    final projection = await _projectionService.getProjection(goalId);
    final currentProgress = projection.totalProgress;
    final newProgress = currentProgress + amount;

    if (newProgress > goal.targetAmount) return false;

    final operation = ReserveOperation(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      sourceId: goalId,
      sourceType: PlanningSourceType.goal,
      accountId: accountId,
      amount: amount,
    );

    try {
      await _engine.execute(operation);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Release all active Goal funding through the Planning Engine.
  Future<void> releaseGoal(String goalId) async {
    final sources = await _projectionService.getFundingSources(goalId);

    for (final source in sources) {
      if (source.amount <= 0) continue;

      final operation = ReleaseOperation(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        sourceId: goalId,
        sourceType: PlanningSourceType.goal,
        accountId: source.accountId,
        amount: source.amount,
      );

      await _engine.execute(operation);
    }
  }

  /// Reduce a Goal allocation for a specific funding account.
  /// ReleasePlanner handles FIFO consumption across active allocations.
  Future<void> reduceAllocation({
    required String goalId,
    required String accountId,
    required double reductionAmount,
  }) async {
    if (reductionAmount <= 0) {
      throw Exception('Reduction amount must be greater than zero');
    }

    final operation = ReleaseOperation(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      sourceId: goalId,
      sourceType: PlanningSourceType.goal,
      accountId: accountId,
      amount: reductionAmount,
    );

    await _engine.execute(operation);
  }

  /// Re-reserve an amount for rollback/recovery through the Planning Engine.
  Future<void> increaseAllocation({
    required String goalId,
    required String accountId,
    required double increaseAmount,
  }) async {
    if (increaseAmount <= 0) {
      throw ArgumentError.value(
        increaseAmount,
        'increaseAmount',
        'Must be greater than zero',
      );
    }

    final operation = ReserveOperation(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      sourceId: goalId,
      sourceType: PlanningSourceType.goal,
      accountId: accountId,
      amount: increaseAmount,
    );

    await _engine.execute(operation);
  }

  /// Temporary compatibility read for existing callers.
  List getGoalAllocations(String goalId) {
    return _allocationService
        .getAll()
        .where((a) => a.type == AllocationType.goal && a.referenceId == goalId)
        .toList();
  }

  /// Release all funding from one Goal funding account through the
  /// Planning Engine.
  Future<void> releaseFundingSource({
    required String goalId,
    required String accountId,
  }) async {
    final sources = await _projectionService.getFundingSources(goalId);

    for (final source in sources) {
      if (source.accountId != accountId || source.amount <= 0) continue;

      final operation = ReleaseOperation(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        sourceId: goalId,
        sourceType: PlanningSourceType.goal,
        accountId: accountId,
        amount: source.amount,
      );

      await _engine.execute(operation);
      return;
    }
  }
}

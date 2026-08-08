import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/engine/executor/default_planning_executor.dart';
import 'package:wafferly/core/planning/engine/planner/planning_execution_plan.dart';
import 'package:wafferly/core/planning/engine/planner/planning_mutation.dart';
import 'package:wafferly/core/planning/infrastructure/identity/memory_allocation_id_generator.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  group('DefaultPlanningExecutor', () {
    test('creates allocation from CreateAllocationMutation', () async {
      // Arrange
      final repository = MemoryAllocationRepository();

      final executor = DefaultPlanningExecutor(
        repository: repository,
        idGenerator: MemoryAllocationIdGenerator(),
      );

      final plan = PlanningExecutionPlan(
        mutations: [
          CreateAllocationMutation(
            allocationId: 'allocation-1',
            createdAt: DateTime(2026, 8, 6),
            sourceId: 'goal-1',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
            amount: 500,
          ),
        ],
      );

      // Act
      await executor.execute(plan);

      // Assert
      final allocation = await repository.findById('allocation-1');

      expect(allocation, isNotNull);
      expect(allocation!.amount, 500);
      expect(allocation.accountId, 'cash');
      expect(allocation.sourceId, 'goal-1');
      expect(allocation.status, AllocationStatus.active);
    });

    test('decreases allocation from DecreaseAllocationMutation', () async {
      // Arrange
      final repository = MemoryAllocationRepository();

      await repository.create(
        Allocation(
          id: 'allocation-1',
          sourceId: 'goal-1',
          sourceType: PlanningSourceType.goal,
          accountId: 'cash',
          amount: 1000,
          status: AllocationStatus.active,
          version: 1,
          createdAt: DateTime(2026, 8, 6),
        ),
      );

      final executor = DefaultPlanningExecutor(
        repository: repository,
        idGenerator: MemoryAllocationIdGenerator(),
      );

      final plan = PlanningExecutionPlan(
        mutations: [
          DecreaseAllocationMutation(allocationId: 'allocation-1', amount: 400),
        ],
      );

      // Act
      await executor.execute(plan);

      // Assert
      final allocation = await repository.findById('allocation-1');

      expect(allocation, isNotNull);
      expect(allocation!.amount, 600);
      expect(allocation.version, 2);
      expect(allocation.updatedAt, isNotNull);

      // Immutable fields remain unchanged.
      expect(allocation.id, 'allocation-1');
      expect(allocation.sourceId, 'goal-1');
      expect(allocation.accountId, 'cash');
    });

    test('releases allocation from DeactivateAllocationMutation', () async {
      // Arrange
      final repository = MemoryAllocationRepository();

      final allocation = Allocation(
        id: 'allocation-1',
        sourceId: 'goal-1',
        sourceType: PlanningSourceType.goal,
        accountId: 'cash',
        amount: 1000,
        status: AllocationStatus.active,
        version: 1,
        createdAt: DateTime(2026, 8, 6),
      );

      await repository.create(allocation);

      final executor = DefaultPlanningExecutor(
        repository: repository,
        idGenerator: MemoryAllocationIdGenerator(),
      );

      final plan = PlanningExecutionPlan(
        mutations: [DeactivateAllocationMutation(allocationId: 'allocation-1')],
      );

      // Act
      await executor.execute(plan);

      // Assert
      final updated = await repository.findById('allocation-1');

      expect(updated, isNotNull);
      expect(updated!.status, AllocationStatus.released);
      expect(updated.version, 2);
      expect(updated.updatedAt, isNotNull);

      // Immutable financial/planning identity remains unchanged.
      expect(updated.id, 'allocation-1');
      expect(updated.sourceId, 'goal-1');
      expect(updated.accountId, 'cash');
      expect(updated.amount, 1000);
    });
  });
}

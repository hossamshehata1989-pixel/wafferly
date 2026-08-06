import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/engine/executor/default_planning_executor.dart';
import 'package:wafferly/core/planning/engine/interpreter/planning_interpreter.dart';
import 'package:wafferly/core/planning/engine/planning_execution_context.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/release_operation.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  group('DefaultPlanningExecutor', () {
    test('creates an allocation when executing ReserveOperation', () async {
      // Arrange
      final repository = MemoryAllocationRepository();

      final executor = DefaultPlanningExecutor(repository: repository);

      final operation = ReserveOperation(
        id: 'op-1',
        createdAt: DateTime(2026, 8, 6),
        sourceId: 'goal-1',
        sourceType: PlanningSourceType.goal,
        accountId: 'cash',
        amount: 500,
      );

      final context = PlanningExecutionContext(
        operation: operation,
        intent: PlanningIntent.reserve,
      );

      // Act
      await executor.execute(context);

      // Assert
      final allocation = await repository.findById('op-1');

      expect(allocation, isNotNull);
      expect(allocation!.amount, 500);
      expect(allocation.accountId, 'cash');
      expect(allocation.sourceId, 'goal-1');
    });

    test('updates an allocation when executing ReleaseOperation', () async {
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

      final executor = DefaultPlanningExecutor(repository: repository);

      final operation = ReleaseOperation(
        id: 'release-1',
        createdAt: DateTime(2026, 8, 6),
        sourceId: 'goal-1',
        sourceType: PlanningSourceType.goal,
        accountId: 'cash',
        amount: 400,
      );

      final context = PlanningExecutionContext(
        operation: operation,
        intent: PlanningIntent.release,
      );

      // Act
      await executor.execute(context);

      // Assert
      final allocation = await repository.findCurrentBySource('goal-1');

      expect(allocation, isNotNull);
      expect(allocation!.amount, 600);
      expect(allocation.version, 2);
      expect(allocation.updatedAt, isNotNull);

      // Ensure immutable fields remain unchanged.
      expect(allocation.id, 'allocation-1');
      expect(allocation.sourceId, 'goal-1');
      expect(allocation.accountId, 'cash');
    });
  });
}

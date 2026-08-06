import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/engine/executor/default_planning_executor.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
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

      // Act
      await executor.execute(operation);

      // Assert
      final Allocation? allocation = await repository.findById('op-1');

      expect(allocation, isNotNull);
      expect(allocation!.amount, 500);
      expect(allocation.accountId, 'cash');
      expect(allocation.sourceId, 'goal-1');
    });
  });
}

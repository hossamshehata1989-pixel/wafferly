import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/planning/engine/guards/cannot_release_more_than_reserved_guard.dart';
import 'package:wafferly/core/planning/engine/interpreter/planning_interpreter.dart';
import 'package:wafferly/core/planning/engine/planning_execution_context.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/operations/release_operation.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  group('CannotReleaseMoreThanReservedGuard', () {
    test('throws when allocation does not exist', () async {
      final repository = MemoryAllocationRepository();

      final guard = CannotReleaseMoreThanReservedGuard(repository: repository);

      final operation = ReleaseOperation(
        id: 'release-1',
        createdAt: DateTime(2026),
        sourceId: 'goal-1',
        sourceType: PlanningSourceType.goal,
        accountId: 'cash',
        amount: 100,
      );

      final context = PlanningExecutionContext(
        operation: operation,
        intent: PlanningIntent.release,
      );

      expect(() => guard.validate(context), throwsStateError);
    });

    test('throws when release amount exceeds reserved amount', () async {
      final repository = MemoryAllocationRepository();

      await repository.create(
        Allocation(
          id: 'allocation-1',
          sourceId: 'goal-1',
          sourceType: PlanningSourceType.goal,
          accountId: 'cash',
          amount: 100,
          status: AllocationStatus.active,
          createdAt: DateTime(2026),
        ),
      );

      final guard = CannotReleaseMoreThanReservedGuard(repository: repository);

      final operation = ReleaseOperation(
        id: 'release-1',
        createdAt: DateTime(2026),
        sourceId: 'goal-1',
        sourceType: PlanningSourceType.goal,
        accountId: 'cash',
        amount: 150,
      );

      final context = PlanningExecutionContext(
        operation: operation,
        intent: PlanningIntent.release,
      );

      expect(() => guard.validate(context), throwsStateError);
    });

    test('passes when release amount is valid', () async {
      final repository = MemoryAllocationRepository();

      await repository.create(
        Allocation(
          id: 'allocation-1',
          sourceId: 'goal-1',
          sourceType: PlanningSourceType.goal,
          accountId: 'cash',
          amount: 100,
          status: AllocationStatus.active,
          createdAt: DateTime(2026),
        ),
      );

      final guard = CannotReleaseMoreThanReservedGuard(repository: repository);

      final operation = ReleaseOperation(
        id: 'release-1',
        createdAt: DateTime(2026),
        sourceId: 'goal-1',
        sourceType: PlanningSourceType.goal,
        accountId: 'cash',
        amount: 60,
      );

      final context = PlanningExecutionContext(
        operation: operation,
        intent: PlanningIntent.release,
      );

      await guard.validate(context);
    });
  });
}

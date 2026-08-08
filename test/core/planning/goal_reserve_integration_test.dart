import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  group('Goal Reserve Planning Integration', () {
    test(
      'creates an active goal allocation through the Planning Engine',
      () async {
        final repository = MemoryAllocationRepository();

        final engine = PlanningEngineBootstrap.create(
          allocationRepository: repository,
        );

        const goalId = 'goal-1';
        const accountId = 'account-1';

        final operation = ReserveOperation(
          id: 'operation-1',
          createdAt: DateTime(2026, 8, 8),
          sourceId: goalId,
          sourceType: PlanningSourceType.goal,
          accountId: accountId,
          amount: 500,
        );

        await engine.execute(operation);

        final allocations = await repository.findBySource(goalId);

        expect(allocations, hasLength(1));

        final allocation = allocations.single;

        expect(allocation.sourceId, goalId);
        expect(allocation.sourceType, PlanningSourceType.goal);
        expect(allocation.accountId, accountId);
        expect(allocation.amount, 500);
        expect(allocation.status, AllocationStatus.active);
      },
    );
  });
}

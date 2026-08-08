import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/engine/planner/handlers/release_planner.dart';
import 'package:wafferly/core/planning/engine/planner/planning_mutation.dart';
import 'package:wafferly/core/planning/engine/planning_execution_context.dart';
import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/release_operation.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';
import 'package:wafferly/core/planning/engine/interpreter/planning_interpreter.dart';

void main() {
  test('ReleasePlanner releases allocations in FIFO order', () async {
    final repository = MemoryAllocationRepository();

    final allocationA = Allocation(
      id: 'allocation-a',
      sourceId: 'goal-1',
      sourceType: PlanningSourceType.goal,
      accountId: 'account-1',
      amount: 1000,
      createdAt: DateTime(2026, 8, 1),
    );

    final allocationB = Allocation(
      id: 'allocation-b',
      sourceId: 'goal-1',
      sourceType: PlanningSourceType.goal,
      accountId: 'account-1',
      amount: 500,
      createdAt: DateTime(2026, 8, 2),
    );

    final allocationC = Allocation(
      id: 'allocation-c',
      sourceId: 'goal-1',
      sourceType: PlanningSourceType.goal,
      accountId: 'account-1',
      amount: 700,
      createdAt: DateTime(2026, 8, 3),
    );

    await repository.create(allocationA);
    await repository.create(allocationB);
    await repository.create(allocationC);

    final planner = ReleasePlanner(repository: repository);

    final operation = ReleaseOperation(
      id: 'release-1',
      createdAt: DateTime(2026, 8, 8),
      sourceId: 'goal-1',
      sourceType: PlanningSourceType.goal,
      accountId: 'account-1',
      amount: 1200,
    );

    final context = PlanningExecutionContext(
      operation: operation,
      intent: PlanningIntent.release,
    );
    final plan = await planner.plan(context);

    expect(plan.mutations.length, 2);

    expect(plan.mutations[0], isA<DeactivateAllocationMutation>());

    final firstMutation = plan.mutations[0] as DeactivateAllocationMutation;

    expect(firstMutation.allocationId, 'allocation-a');

    expect(plan.mutations[1], isA<DecreaseAllocationMutation>());

    final secondMutation = plan.mutations[1] as DecreaseAllocationMutation;

    expect(secondMutation.allocationId, 'allocation-b');
    expect(secondMutation.amount, 200);
  });
}

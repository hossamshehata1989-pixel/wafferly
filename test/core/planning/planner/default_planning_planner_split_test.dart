import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/engine/planner/default_planning_planner.dart';
import 'package:wafferly/core/planning/engine/planner/planning_execution_plan.dart';
import 'package:wafferly/core/planning/engine/planner/planning_mutation.dart';
import 'package:wafferly/core/planning/engine/planning_execution_context.dart';
import 'package:wafferly/core/planning/engine/interpreter/planning_interpreter.dart';
import 'package:wafferly/core/planning/infrastructure/identity/memory_allocation_id_generator.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/entities/allocation.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_reference.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';
import 'package:wafferly/core/planning/operations/split_operation.dart';
import 'package:wafferly/core/planning/engine/planner/handlers/reserve_planner.dart';
import 'package:wafferly/core/planning/engine/planner/handlers/release_planner.dart';
import 'package:wafferly/core/planning/engine/planner/handlers/split_planner.dart';
import 'package:wafferly/core/planning/engine/planner/handlers/merge_planner.dart';

void main() {
  group('DefaultPlanningPlanner SplitOperation', () {
    test(
      'creates CreateAllocationMutation when target allocation does not exist',
      () async {
        final repository = MemoryAllocationRepository();

        await repository.create(
          Allocation(
            id: 'vacation-allocation',
            sourceId: 'vacation',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
            amount: 1000,
            status: AllocationStatus.active,
            createdAt: DateTime(2026, 8, 7),
          ),
        );

        final planner = DefaultPlanningPlanner(
          reservePlanner: ReservePlanner(
            idGenerator: MemoryAllocationIdGenerator(),
          ),
          releasePlanner: ReleasePlanner(repository: repository),
          splitPlanner: SplitPlanner(
            repository: repository,
            idGenerator: MemoryAllocationIdGenerator(),
          ),
          mergePlanner: MergePlanner(repository: repository),
        );

        final context = PlanningExecutionContext(
          operation: SplitOperation(
            id: 'split-1',
            createdAt: DateTime(2026, 8, 7),
            source: const PlanningSourceReference(
              id: 'vacation',
              type: PlanningSourceType.goal,
            ),
            target: const PlanningSourceReference(
              id: 'emergency',
              type: PlanningSourceType.goal,
            ),
            accountId: 'cash',
            amount: 400,
          ),
          intent: PlanningIntent.split,
        );

        final PlanningExecutionPlan plan = await planner.plan(context);

        expect(plan.mutations.length, 2);

        final decrease = plan.mutations[0] as DecreaseAllocationMutation;
        final create = plan.mutations[1] as CreateAllocationMutation;

        expect(decrease.amount, 400);
        expect(decrease.allocationId, 'vacation-allocation');

        expect(create.amount, 400);
        expect(create.sourceId, 'emergency');
        expect(create.accountId, 'cash');
      },
    );
    // ===============================================================

    test(
      'creates IncreaseAllocationMutation when target allocation already exists',
      () async {
        final repository = MemoryAllocationRepository();

        await repository.create(
          Allocation(
            id: 'vacation-allocation',
            sourceId: 'vacation',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
            amount: 1000,
            status: AllocationStatus.active,
            createdAt: DateTime(2026, 8, 7),
          ),
        );

        await repository.create(
          Allocation(
            id: 'emergency-allocation',
            sourceId: 'emergency',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
            amount: 250,
            status: AllocationStatus.active,
            createdAt: DateTime(2026, 8, 7),
          ),
        );

        final planner = DefaultPlanningPlanner(
          reservePlanner: ReservePlanner(
            idGenerator: MemoryAllocationIdGenerator(),
          ),
          releasePlanner: ReleasePlanner(repository: repository),
          splitPlanner: SplitPlanner(
            repository: repository,
            idGenerator: MemoryAllocationIdGenerator(),
          ),
          mergePlanner: MergePlanner(repository: repository),
        );

        final context = PlanningExecutionContext(
          operation: SplitOperation(
            id: 'split-2',
            createdAt: DateTime(2026, 8, 7),
            source: const PlanningSourceReference(
              id: 'vacation',
              type: PlanningSourceType.goal,
            ),
            target: const PlanningSourceReference(
              id: 'emergency',
              type: PlanningSourceType.goal,
            ),
            accountId: 'cash',
            amount: 400,
          ),
          intent: PlanningIntent.split,
        );

        final plan = await planner.plan(context);

        expect(plan.mutations.length, 2);

        final decrease = plan.mutations[0] as DecreaseAllocationMutation;
        final increase = plan.mutations[1] as IncreaseAllocationMutation;

        expect(decrease.allocationId, 'vacation-allocation');
        expect(decrease.amount, 400);

        expect(increase.allocationId, 'emergency-allocation');
        expect(increase.amount, 400);
      },
    );

    // ===============================================================

    test('throws when source allocation does not exist', () async {
      final repository = MemoryAllocationRepository();

      final planner = DefaultPlanningPlanner(
        reservePlanner: ReservePlanner(
          idGenerator: MemoryAllocationIdGenerator(),
        ),
        releasePlanner: ReleasePlanner(repository: repository),
        splitPlanner: SplitPlanner(
          repository: repository,
          idGenerator: MemoryAllocationIdGenerator(),
        ),
        mergePlanner: MergePlanner(repository: repository),
      );

      final context = PlanningExecutionContext(
        operation: SplitOperation(
          id: 'split-3',
          createdAt: DateTime(2026, 8, 7),
          source: const PlanningSourceReference(
            id: 'missing',
            type: PlanningSourceType.goal,
          ),
          target: const PlanningSourceReference(
            id: 'emergency',
            type: PlanningSourceType.goal,
          ),
          accountId: 'cash',
          amount: 400,
        ),
        intent: PlanningIntent.split,
      );

      expect(() => planner.plan(context), throwsA(isA<StateError>()));
    });

    // ==============================================================
  });
}

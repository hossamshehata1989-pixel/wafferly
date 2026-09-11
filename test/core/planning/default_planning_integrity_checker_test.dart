import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/engine/integrity/'
    'default_planning_integrity_checker.dart';
import 'package:wafferly/core/planning/engine/planner/'
    'planning_execution_plan.dart';
import 'package:wafferly/core/planning/engine/planner/'
    'planning_mutation.dart';
import 'package:wafferly/core/planning/value_objects/'
    'planning_source_type.dart';
import 'package:wafferly/core/money/money.dart';
void main() {
  group('DefaultPlanningIntegrityChecker', () {
    const checker = DefaultPlanningIntegrityChecker();

    test('accepts a valid create allocation plan', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          CreateAllocationMutation(
            allocationId: 'allocation-1',
            createdAt: DateTime(2026, 9, 9),
            sourceId: 'goal-1',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
            amount: Money.parse('500'),
          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        completes,
      );
    });

    test('rejects an empty plan', () async {
      final plan = PlanningExecutionPlan(
        mutations: const [],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(
          isA<StateError>(),
        ),
      );
    });

    test('rejects blank allocation id', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          CreateAllocationMutation(
            allocationId: '   ',
            createdAt: DateTime(2026, 9, 9),
            sourceId: 'goal-1',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
amount: Money.parse('500'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects blank source id', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          CreateAllocationMutation(
            allocationId: 'allocation-1',
            createdAt: DateTime(2026, 9, 9),
            sourceId: '',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
amount: Money.parse('500'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects blank account id', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          CreateAllocationMutation(
            allocationId: 'allocation-1',
            createdAt: DateTime(2026, 9, 9),
            sourceId: 'goal-1',
            sourceType: PlanningSourceType.goal,
            accountId: '',
amount: Money.parse('500'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects zero amount', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          CreateAllocationMutation(
            allocationId: 'allocation-1',
            createdAt: DateTime(2026, 9, 9),
            sourceId: 'goal-1',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
            amount: Money.zero,
          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects negative amount', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          CreateAllocationMutation(
            allocationId: 'allocation-1',
            createdAt: DateTime(2026, 9, 9),
            sourceId: 'goal-1',
            sourceType: PlanningSourceType.goal,
            accountId: 'cash',
amount: Money.parse('-100'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts valid increase mutation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          IncreaseAllocationMutation(
            allocationId: 'allocation-1',
            amount: Money.parse('200'),
          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        completes,
      );
    });

    test('accepts valid decrease mutation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DecreaseAllocationMutation(
            allocationId: 'allocation-1',
amount: Money.parse('200'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        completes,
      );
    });

    test('accepts valid deactivate mutation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DeactivateAllocationMutation(
            allocationId: 'allocation-1',
          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        completes,
      );
    });

    test('rejects increase after deactivation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DeactivateAllocationMutation(
            allocationId: 'allocation-1',
          ),
          IncreaseAllocationMutation(
            allocationId: 'allocation-1',
amount: Money.parse('100'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects decrease after deactivation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DeactivateAllocationMutation(
            allocationId: 'allocation-1',
          ),
          DecreaseAllocationMutation(
            allocationId: 'allocation-1',
amount: Money.parse('100'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects duplicate deactivation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DeactivateAllocationMutation(
            allocationId: 'allocation-1',
          ),
          DeactivateAllocationMutation(
            allocationId: 'allocation-1',
          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects blank allocation id in increase mutation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          IncreaseAllocationMutation(
            allocationId: ' ',
amount: Money.parse('100'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects blank allocation id in decrease mutation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DecreaseAllocationMutation(
            allocationId: '',
amount: Money.parse('100'),          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects blank allocation id in deactivate mutation', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DeactivateAllocationMutation(
            allocationId: '',
          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts multiple independent mutations', () async {
      final plan = PlanningExecutionPlan(
        mutations: [
          DecreaseAllocationMutation(
            allocationId: 'allocation-1',
amount: Money.parse('100'),          ),
          IncreaseAllocationMutation(
            allocationId: 'allocation-2',
amount: Money.parse('200'),          ),
          DeactivateAllocationMutation(
            allocationId: 'allocation-3',
          ),
        ],
      );

      await expectLater(
        checker.validate(plan),
        completes,
      );
    });
  });
}
import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/core/planning/engine/guards/positive_amount_guard.dart';
import 'package:wafferly/core/planning/engine/interpreter/planning_interpreter.dart';
import 'package:wafferly/core/planning/engine/planning_execution_context.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';

void main() {
  group('PositiveAmountGuard', () {
    const guard = PositiveAmountGuard();

    test('accepts positive reserve amount', () async {
      final context = PlanningExecutionContext(
        operation: ReserveOperation(
          id: '1',
          createdAt: DateTime(2026),
          sourceId: 'goal',
          sourceType: PlanningSourceType.goal,
          accountId: 'cash',
          amount: 500,
        ),
        intent: PlanningIntent.reserve,
      );

      await guard.validate(context);
    });

    test('throws for zero amount', () async {
      final context = PlanningExecutionContext(
        operation: ReserveOperation(
          id: '1',
          createdAt: DateTime(2026),
          sourceId: 'goal',
          sourceType: PlanningSourceType.goal,
          accountId: 'cash',
          amount: 0,
        ),
        intent: PlanningIntent.reserve,
      );

      expect(() => guard.validate(context), throwsArgumentError);
    });

    test('throws for negative amount', () async {
      final context = PlanningExecutionContext(
        operation: ReserveOperation(
          id: '1',
          createdAt: DateTime(2026),
          sourceId: 'goal',
          sourceType: PlanningSourceType.goal,
          accountId: 'cash',
          amount: -250,
        ),
        intent: PlanningIntent.reserve,
      );

      expect(() => guard.validate(context), throwsArgumentError);
    });
  });
}

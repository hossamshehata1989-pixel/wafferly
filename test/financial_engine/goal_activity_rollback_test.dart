import 'package:wafferly/core/money/money.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/financial_engine/execution/financial_transaction_context.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/mutations/goal_activity_mutation.dart';

import 'package:wafferly/infrastructure/adapters/goal_activity_adapter.dart'
    as infrastructure;

import 'package:wafferly/models/goal_activity.dart' as goal_model;

import 'package:wafferly/services/goal_activity_service.dart';

void main() {
  late Directory testDirectory;
  late Box<goal_model.GoalActivity> goalActivitiesBox;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_goal_activity_rollback_test_',
    );

    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(90)) {
      Hive.registerAdapter(goal_model.GoalActivityAdapter());
    }

    goalActivitiesBox = await Hive.openBox<goal_model.GoalActivity>(
      'goal_activities',
    );
  });

  tearDown(() async {
    await Hive.close();

    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  test(
    'goal activity is rolled back when a later mutation fails',
    () async {
      final activityService = GoalActivityService();

      final adapter = infrastructure.GoalActivityAdapter(
        service: activityService,
      );

      final mutation = GoalActivityMutation(
        goalId: 'goal-activity-rollback-001',
        sourceAccountId: 'cash',
        destinationAccountId: 'saving',
        amount: Money.fromDouble(500),
        activityType: goal_model.GoalActivityType.transferToSaving,
      );

      final unitOfWork = MemoryFinancialUnitOfWork();

      try {
        await unitOfWork.execute(
          (FinancialTransactionContext context) async {
            await adapter.recordActivity(
  mutation,
  context,
);

            expect(
              goalActivitiesBox.values,
              hasLength(1),
            );

            throw StateError(
              'forced failure after goal activity',
            );
          },
        );
      } on StateError {
        // Expected failure.
      }

      expect(
        goalActivitiesBox.values,
        isEmpty,
        reason: 'Goal Activity must be removed during rollback.',
      );
    },
  );
}
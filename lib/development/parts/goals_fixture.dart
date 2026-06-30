import 'package:flutter/foundation.dart';

import '../../../models/goal.dart';
import '../../../models/enums/goal_type.dart';
import '../../../services/goal_service.dart';

class GoalsFixture {
  const GoalsFixture._();

  static Future<void> seed(GoalService goalService) async {
    debugPrint('Creating demo goals...');
    // حذف كل الأهداف القديمة
    final existing = goalService.getAll();

    for (final goal in existing) {
      await goalService.delete(goal.id);
    }

    // Emergency Fund
    await goalService.add(
      Goal.create(
        title: 'Emergency Fund',
        targetAmount: 50000,
        reserveMoney: true,
        type: GoalType.manual,
      ),
    );

    // Laptop
    await goalService.add(
      Goal.create(
        title: 'New Laptop',
        targetAmount: 90000,
        reserveMoney: false,
        type: GoalType.manual,
      ),
    );
    debugPrint('Goals created successfully');
    debugPrint('Goals count: ${goalService.getAll().length}');
  }
}

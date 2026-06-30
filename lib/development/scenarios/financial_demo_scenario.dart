import 'package:flutter/foundation.dart';

import '../../services/account_service.dart';
import '../../services/goal_service.dart';

import '../parts/accounts_fixture.dart';
import '../parts/goals_fixture.dart';

class FinancialDemoScenario {
  const FinancialDemoScenario._();

  static Future<void> seed() async {
    debugPrint('Scenario Started');

    final accountService = AccountService();
    final goalService = GoalService();

    await AccountsFixture.seed(accountService);

    await GoalsFixture.seed(goalService);

    debugPrint('Scenario Finished');

    // TODO
    // CommitmentsFixture.seed();
    // ScheduleRulesFixture.seed();
  }
}

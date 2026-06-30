import 'scenarios/financial_demo_scenario.dart';
import 'package:flutter/foundation.dart';

class DevelopmentDataSeeder {
  const DevelopmentDataSeeder._();

  static Future<void> seedFinancialDemo() async {
    debugPrint('Seeder Started');

    await FinancialDemoScenario.seed();

    debugPrint('Seeder Finished');
  }
}

// lib/models/enums/budget_period.dart

import 'package:hive/hive.dart';

part 'budget_period.g.dart';

@HiveType(typeId: 40)
enum BudgetPeriod {
  @HiveField(0)
  weekly,
  @HiveField(1)
  monthly,
  @HiveField(2)
  yearly,
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get string {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }

  static BudgetPeriod fromString(String value) {
    switch (value) {
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }
}

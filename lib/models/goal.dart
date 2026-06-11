// lib/models/goal.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'enums/goal_status.dart';
import 'enums/goal_type.dart';

part 'goal.g.dart';

@HiveType(typeId: 60)
class Goal {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final DateTime? targetDate;

  @HiveField(4)
  final bool reserveMoney;

  @HiveField(5)
  final GoalStatus status;

  @HiveField(6)
  final GoalType type;

  // ✅ جديد: ملاحظات المستخدم
  @HiveField(7)
  final String? notes;

  // ✅ جديد: قاعدة التكرار (مثال: 'monthly', 'weekly', 'every_2_weeks')
  @HiveField(8)
  final String? recurringRule;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.type,
    this.targetDate,
    required this.reserveMoney,
    required this.status,
    this.notes,
    this.recurringRule,
  });

  factory Goal.create({
    required String title,
    required double targetAmount,
    GoalType type = GoalType.manual,
    DateTime? targetDate,
    bool reserveMoney = false,
    String? notes,
    String? recurringRule,
  }) {
    return Goal(
      id: const Uuid().v4(),
      title: title,
      targetAmount: targetAmount,
      type: type,
      targetDate: targetDate,
      reserveMoney: reserveMoney,
      status: GoalStatus.active,
      notes: notes,
      recurringRule: recurringRule,
    );
  }

  Goal copyWith({
    GoalStatus? status,
    GoalType? type,
    String? notes,
    String? recurringRule,
  }) {
    return Goal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      type: type ?? this.type,
      targetDate: targetDate,
      reserveMoney: reserveMoney,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      recurringRule: recurringRule ?? this.recurringRule,
    );
  }
}

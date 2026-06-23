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

  @HiveField(9)
  final double? contributionAmount;

  @HiveField(10)
  final DateTime? nextDueDate;

  @HiveField(11)
  final String? preferredSourceAccountId;

  @HiveField(12)
  final String? preferredSavingAccountId;

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
    this.contributionAmount,
    this.nextDueDate,

    this.preferredSourceAccountId,
    this.preferredSavingAccountId,
  });

  factory Goal.create({
    required String title,
    required double targetAmount,
    GoalType type = GoalType.manual,
    DateTime? targetDate,
    bool reserveMoney = false,
    String? notes,
    String? recurringRule,

    double? contributionAmount,
    DateTime? nextDueDate,

    String? preferredSourceAccountId,
    String? preferredSavingAccountId,
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
      contributionAmount: contributionAmount,
      nextDueDate: nextDueDate,
      preferredSourceAccountId: preferredSourceAccountId,
      preferredSavingAccountId: preferredSavingAccountId,
    );
  }

  Goal copyWith({
    GoalStatus? status,
    GoalType? type,
    String? notes,
    String? recurringRule,

    double? contributionAmount,
    DateTime? nextDueDate,

    String? preferredSourceAccountId,
    String? preferredSavingAccountId,
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
      contributionAmount: contributionAmount ?? this.contributionAmount,
      nextDueDate: nextDueDate ?? this.nextDueDate,

      preferredSourceAccountId:
          preferredSourceAccountId ?? this.preferredSourceAccountId,

      preferredSavingAccountId:
          preferredSavingAccountId ?? this.preferredSavingAccountId,
    );
  }
}

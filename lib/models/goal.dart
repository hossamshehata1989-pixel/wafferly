// lib/models/goal.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'enums/goal_status.dart';

part 'goal.g.dart';

@HiveType(typeId: 60)
class Goal {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final double targetAmount;

  @HiveField(5)
  final DateTime? targetDate;

  @HiveField(6)
  final bool reserveMoney;

  @HiveField(7)
  final GoalStatus status;

  Goal({
    required this.id,
    required this.accountId,
    required this.title,
    required this.targetAmount,
    this.targetDate,
    required this.reserveMoney,
    required this.status,
  });

  factory Goal.create({
    required String accountId,
    required String title,
    required double targetAmount,
    DateTime? targetDate,
    bool reserveMoney = false,
  }) {
    return Goal(
      id: const Uuid().v4(),
      accountId: accountId,
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
      reserveMoney: reserveMoney,
      status: GoalStatus.active,
    );
  }

  Goal copyWith({GoalStatus? status}) {
    return Goal(
      id: id,
      accountId: accountId,
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
      reserveMoney: reserveMoney,
      status: status ?? this.status,
    );
  }
}

// lib/models/goal_activity.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'goal_activity.g.dart';

/// Constants for GoalActivity types
class GoalActivityType {
  static const String reserve = 'reserve';
  static const String release = 'release';
  static const String cancel = 'cancel';
  static const String completedReserved = 'completed_reserved';
  static const String completedRelease = 'completed_release';
  static const String transferToSaving = 'transfer_to_saving';
}

@HiveType(typeId: 90)
class GoalActivity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String goalId;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String? sourceAccountId;

  @HiveField(5)
  final String? destinationAccountId;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdAt;

  GoalActivity({
    required this.id,
    required this.goalId,
    required this.type,
    required this.amount,
    this.sourceAccountId,
    this.destinationAccountId,
    this.notes,
    required this.createdAt,
  });

  factory GoalActivity.create({
    required String goalId,
    required String type,
    required double amount,
    String? sourceAccountId,
    String? destinationAccountId,
    String? notes,
  }) {
    return GoalActivity(
      id: const Uuid().v4(),
      goalId: goalId,
      type: type,
      amount: amount,
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}

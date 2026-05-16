// lib/models/budget.dart

import 'package:hive/hive.dart';
import 'enums/budget_period.dart';

part 'budget.g.dart';

@HiveType(typeId: 41)
class Budget {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final BudgetPeriod period;

  @HiveField(4)
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.createdAt,
  });

  factory Budget.create({
    required String categoryId,
    required double amount,
    required BudgetPeriod period,
  }) {
    return Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: categoryId,
      amount: amount,
      period: period,
      createdAt: DateTime.now(),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      categoryId: json['categoryId'],
      amount: json['amount'],
      period: BudgetPeriodExtension.fromString(json['period']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'period': period.string,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

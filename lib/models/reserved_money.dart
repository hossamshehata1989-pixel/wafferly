// lib/models/reserved_money.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'enums/reserved_money_type.dart';

part 'reserved_money.g.dart';

@HiveType(typeId: 51) // ✅ متطابق مع main.dart
class ReservedMoney {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final ReservedMoneyType type;

  @HiveField(5)
  final DateTime createdAt;

  ReservedMoney({
    required this.id,
    required this.accountId,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  factory ReservedMoney.create({
    required String accountId,
    required String title,
    required double amount,
    required ReservedMoneyType type,
  }) {
    return ReservedMoney(
      id: const Uuid().v4(),
      accountId: accountId,
      title: title,
      amount: amount,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  factory ReservedMoney.fromJson(Map<String, dynamic> json) {
    return ReservedMoney(
      id: json['id'],
      accountId: json['accountId'],
      title: json['title'],
      amount: json['amount'],
      type: ReservedMoneyTypeExtension.fromString(json['type']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'title': title,
      'amount': amount,
      'type': type.string,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReservedMoney copyWith({
    String? id,
    String? accountId,
    String? title,
    double? amount,
    ReservedMoneyType? type,
    DateTime? createdAt,
  }) {
    return ReservedMoney(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

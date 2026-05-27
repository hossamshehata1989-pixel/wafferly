// lib/models/transaction.dart

import 'package:hive/hive.dart';
import '../constants/transaction_constants.dart';

part 'transaction.g.dart';

@HiveType(typeId: 10)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String type; // income / expense / transfer / debt

  @HiveField(3)
  final String? fromAccountId;

  @HiveField(4)
  final String? toAccountId;

  @HiveField(5)
  final String categoryId;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String? note;

  @HiveField(8)
  final String paymentMethod;

  @HiveField(9)
  final bool isExceptional;

  @HiveField(10)
  final String? subCategoryId;

  @HiveField(11)
  final String currencyCode;

  @HiveField(12)
  final String source;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  @HiveField(15)
  final String? actorMemberId; // ✅ behavioral attribution layer

  Transaction({
    String? id,
    required this.amount,
    required this.type,
    this.fromAccountId,
    this.toAccountId,
    required this.categoryId,
    required this.date,
    this.note,
    this.paymentMethod = 'cash',
    this.isExceptional = false,
    this.subCategoryId,
    String? currencyCode,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.actorMemberId,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       currencyCode = currencyCode ?? 'EGP',
       source = source ?? TransactionSource.manual,
       createdAt = createdAt ?? date,
       updatedAt = updatedAt ?? date;

  Transaction copyWith({
    String? id,
    double? amount,
    String? type,
    String? fromAccountId,
    String? toAccountId,
    String? categoryId,
    DateTime? date,
    String? note,
    String? paymentMethod,
    bool? isExceptional,
    String? subCategoryId,
    String? currencyCode,
    String? source,
    DateTime? updatedAt,
    String? actorMemberId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isExceptional: isExceptional ?? this.isExceptional,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      currencyCode: currencyCode ?? this.currencyCode,
      source: source ?? this.source,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      actorMemberId: actorMemberId ?? this.actorMemberId,
    );
  }

  factory Transaction.create({
    String? id,
    required double amount,
    required String type,
    String? fromAccountId,
    String? toAccountId,
    required String categoryId,
    required DateTime date,
    String? note,
    String paymentMethod = 'cash',
    bool isExceptional = false,
    String? subCategoryId,
    String? currencyCode,
    String? source,
    String? actorMemberId,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: id ?? now.millisecondsSinceEpoch.toString(),
      amount: amount,
      type: type,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      date: date,
      note: note,
      paymentMethod: paymentMethod,
      isExceptional: isExceptional,
      subCategoryId: subCategoryId,
      currencyCode: currencyCode,
      source: source,
      actorMemberId: actorMemberId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Transaction touch() => copyWith(updatedAt: DateTime.now());

  Transaction withSource(String newSource) =>
      copyWith(source: newSource, updatedAt: DateTime.now());

  bool get isLegacy =>
      source == TransactionSource.manual &&
      createdAt == date &&
      updatedAt == date;
}

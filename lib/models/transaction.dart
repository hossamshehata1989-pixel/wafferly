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

  // ==================== الحقول الجديدة ====================
  
  @HiveField(11)
  final String currencyCode;  // non-nullable, default = 'EGP'
  
  @HiveField(12)
  final String source;  // non-nullable, default = TransactionSource.manual
  
  @HiveField(13)
  final DateTime createdAt;
  
  @HiveField(14)
  final DateTime updatedAt;

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
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       currencyCode = currencyCode ?? 'EGP',
       source = source ?? TransactionSource.manual,
       createdAt = createdAt ?? date,  // ✅ للبيانات القديمة: نفس تاريخ المعاملة
       updatedAt = updatedAt ?? date;  // ✅ للبيانات القديمة: نفس تاريخ المعاملة

  // ==================== copyWith ====================
  
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
    );
  }

  // ==================== مُنشئ للمعاملات الجديدة ====================
  
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
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==================== تحديث updatedAt ====================
  
  Transaction touch() {
    return copyWith(updatedAt: DateTime.now());
  }

  // ==================== تغيير المصدر (للترحيل) ====================
  
  Transaction withSource(String newSource) {
    return copyWith(source: newSource, updatedAt: DateTime.now());
  }

  // ==================== هل هي معاملة قديمة (قبل التحديث)؟ ====================
  
  bool get isLegacy => 
      source == TransactionSource.manual && 
      createdAt == date && 
      updatedAt == date;
}
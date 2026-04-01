// lib/models/expense.dart
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id; // ✅ إضافة id فريد
  
  @HiveField(1)
  final double amount;
  
  @HiveField(2)
  final String mainCategory;
  
  @HiveField(3)
  final String subCategory;
  
  @HiveField(4)
  final DateTime date;
  
  @HiveField(5)
  final bool isExceptional;
  
  @HiveField(6)
  final String? note;
  
  @HiveField(7)
  final String paymentMethod;

  Expense({
    String? id,
    required this.amount,
    required this.mainCategory,
    required this.subCategory,
    required this.date,
    required this.isExceptional,
    this.note,
    this.paymentMethod = 'cash',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  // ✅ نسخة للتعديل
  Expense copyWith({
    double? amount,
    String? mainCategory,
    String? subCategory,
    DateTime? date,
    bool? isExceptional,
    String? note,
    String? paymentMethod,
  }) {
    return Expense(
      id: this.id,
      amount: amount ?? this.amount,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      date: date ?? this.date,
      isExceptional: isExceptional ?? this.isExceptional,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
// lib/models/expense.dart
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double amount;
  
  @HiveField(2)
  final String mainCategoryId;  // ✅ id الفئة الرئيسية (مثلاً 'dailyTransport')
  
  
  @HiveField(4)
  final String? subCategoryId;   // ✅ id الفئة الفرعية (اختياري)
  
  
  @HiveField(6)
  final DateTime date;
  
  @HiveField(7)
  final bool isExceptional;
  
  @HiveField(8)
  final String? note;
  
  @HiveField(9)
  final String paymentMethod;

  Expense({
    String? id,
    required this.amount,
    required this.mainCategoryId,
   
    this.subCategoryId,
   
    required this.date,
    required this.isExceptional,
    this.note,
    this.paymentMethod = 'cash',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  // ✅ نسخة للتعديل
 Expense copyWith({
  String? id,
  double? amount,
  String? mainCategoryId,
  String? subCategoryId,
  DateTime? date,
  bool? isExceptional,
  String? note,
  String? paymentMethod,
}) {
  return Expense(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    mainCategoryId: mainCategoryId ?? this.mainCategoryId,
    subCategoryId: subCategoryId ?? this.subCategoryId,
    date: date ?? this.date,
    isExceptional: isExceptional ?? this.isExceptional,
    note: note ?? this.note,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );
}
}
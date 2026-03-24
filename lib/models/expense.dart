import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final bool isExceptional; // 🔥 الجديد

  Expense({
    required this.amount,
    required this.category,
    required this.date,
    required this.isExceptional,
  });
}
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {

  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String mainCategory;

  @HiveField(2)
  final String subCategory;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final bool isExceptional;

  Expense({
    required this.amount,
    required this.mainCategory,
    required this.subCategory,
    required this.date,
    required this.isExceptional,
  });
}
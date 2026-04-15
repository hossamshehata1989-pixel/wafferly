import 'package:hive/hive.dart';

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
  final String fromAccountId;

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

  Transaction({
  String? id,
  required this.amount,
  required this.type,
  required this.fromAccountId,
  this.toAccountId,
  required this.categoryId,
  required this.date,
  this.note,
  this.paymentMethod = 'cash',
  this.isExceptional = false,
}) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
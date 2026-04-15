import 'package:hive/hive.dart';
part 'account.g.dart';

@HiveType(typeId: 11)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // cash / bank / credit / loan / asset

  @HiveField(3)
  final String currency;

  @HiveField(4)
  final double balance;

  Account({
    String? id,
    required this.name,
    required this.type,
    required this.currency,
    this.balance = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
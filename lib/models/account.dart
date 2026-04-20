import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 1)
class Account extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bookId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String type;

  @HiveField(4)
  String nature;

  @HiveField(5)
  String currency;

  @HiveField(6)
  String? provider;

  @HiveField(7)
  String? accountNumber;

  @HiveField(8)
  String? color;

  @HiveField(9)
  String? icon;

  @HiveField(10)
  String? notes;

  @HiveField(11)
  DateTime createdAt;

  Account({
    required this.id,
    required this.bookId,
    required this.name,
    required this.type,
    required this.nature,
    required this.currency,
    this.provider,
    this.accountNumber,
    this.color,
    this.icon,
    this.notes,
    required this.createdAt,
  });
}
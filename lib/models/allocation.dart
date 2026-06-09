import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'enums/allocation_type.dart';

part 'allocation.g.dart';

@HiveType(typeId: 80)
class Allocation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final AllocationType type;

  @HiveField(4)
  final String referenceId;

  @HiveField(5)
  final DateTime createdAt;

  Allocation({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.referenceId,
    required this.createdAt,
  });

  factory Allocation.create({
    required String accountId,
    required double amount,
    required AllocationType type,
    required String referenceId,
  }) {
    return Allocation(
      id: const Uuid().v4(),
      accountId: accountId,
      amount: amount,
      type: type,
      referenceId: referenceId,
      createdAt: DateTime.now(),
    );
  }
}

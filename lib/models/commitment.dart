import 'package:hive/hive.dart';

import 'enums/commitment_amount_mode.dart';
import 'enums/commitment_status.dart';
import 'enums/commitment_type.dart';
part 'commitment.g.dart';

@HiveType(typeId: 96)
class Commitment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final CommitmentType type;

  @HiveField(3)
  final CommitmentStatus status;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final CommitmentAmountMode amountMode;

  @HiveField(6)
  final String? sourceAccountId;

  @HiveField(7)
  final String? destinationAccountId;

  @HiveField(8)
  final String scheduleRuleId;

  @HiveField(9)
  final String? liabilityAccountId;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final bool isArchived;

  const Commitment({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.amount,
    required this.amountMode,
    required this.scheduleRuleId,
    this.sourceAccountId,
    this.destinationAccountId,
    this.liabilityAccountId,
    this.notes,
    this.isArchived = false,
  });

  Commitment copyWith({
    String? title,
    CommitmentType? type,
    CommitmentStatus? status,
    double? amount,
    CommitmentAmountMode? amountMode,
    String? sourceAccountId,
    String? destinationAccountId,
    String? scheduleRuleId,
    String? liabilityAccountId,
    String? notes,
    bool? isArchived,
  }) {
    return Commitment(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      amountMode: amountMode ?? this.amountMode,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      scheduleRuleId: scheduleRuleId ?? this.scheduleRuleId,
      liabilityAccountId: liabilityAccountId ?? this.liabilityAccountId,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

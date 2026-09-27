import 'package:hive/hive.dart';

import '../../core/money/money.dart';

part 'financing_installment.g.dart';

/// One expected repayment obligation produced by a FinancingSchedule.
///
/// Actual payment remains FinancialOperationEngine territory.
@HiveType(typeId: 112)
class FinancingInstallment {
  @HiveField(0)
  final String installmentId;

  @HiveField(1)
  final String contractId;

  @HiveField(2)
  final String scheduleId;

  @HiveField(3)
  final String? occurrenceId;

  @HiveField(4)
  final int sequence;

  @HiveField(5)
  final DateTime dueDate;

  @HiveField(6)
  final String openingPrincipalValue;

  @HiveField(7)
  final String principalComponentValue;

  @HiveField(8)
  final String interestComponentValue;

  @HiveField(9)
  final String feesValue;

  @HiveField(10)
  final String amountValue;

  @HiveField(11)
  final String status;

  const FinancingInstallment({
    required this.installmentId,
    required this.contractId,
    required this.scheduleId,
    required this.sequence,
    required this.dueDate,
    required this.openingPrincipalValue,
    required this.principalComponentValue,
    required this.interestComponentValue,
    required this.feesValue,
    required this.amountValue,
    required this.status,
    this.occurrenceId,
  });

  Money get openingPrincipal => Money.parse(openingPrincipalValue);
  Money get principalComponent => Money.parse(principalComponentValue);
  Money get interestComponent => Money.parse(interestComponentValue);
  Money get fees => Money.parse(feesValue);
  Money get amount => Money.parse(amountValue);

  Money get calculatedComponentTotal =>
      principalComponent + interestComponent + fees;
}

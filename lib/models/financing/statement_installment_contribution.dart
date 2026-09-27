import 'package:hive/hive.dart';

import '../../core/money/money.dart';

part 'statement_installment_contribution.g.dart';

/// Immutable relationship/read-model row connecting one installment to one
/// statement cycle.
///
/// It is presentation/period state, not financial truth, and must never be
/// used as a source for Account balance or Ledger mutation.
@HiveType(typeId: 113)
class StatementInstallmentContribution {
  @HiveField(0)
  final String contributionId;

  @HiveField(1)
  final String statementId;

  @HiveField(2)
  final String contractId;

  @HiveField(3)
  final String installmentId;

  @HiveField(4)
  final String principalValue;

  @HiveField(5)
  final String interestValue;

  @HiveField(6)
  final String feesValue;

  @HiveField(7)
  final String contributionValue;

  @HiveField(8)
  final DateTime createdAt;

  const StatementInstallmentContribution({
    required this.contributionId,
    required this.statementId,
    required this.contractId,
    required this.installmentId,
    required this.principalValue,
    required this.interestValue,
    required this.feesValue,
    required this.contributionValue,
    required this.createdAt,
  });

  static String idFor({
    required String statementId,
    required String installmentId,
  }) => '$statementId|$installmentId';

  Money get principal => Money.parse(principalValue);
  Money get interest => Money.parse(interestValue);
  Money get fees => Money.parse(feesValue);
  Money get contribution => Money.parse(contributionValue);
}

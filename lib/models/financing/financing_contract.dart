import 'package:hive/hive.dart';

import '../../core/money/money.dart';

part 'financing_contract.g.dart';

/// Persisted contractual financing terms.
///
/// This model is NOT financial truth. The authoritative liability remains
/// Account + effective financial transactions.
@HiveType(typeId: 110)
class FinancingContract {
  @HiveField(0)
  final String contractId;

  @HiveField(1)
  final String liabilityAccountId;

  @HiveField(2)
  final String originReference;

  @HiveField(3)
  final String principalValue;

  @HiveField(4)
  final int installmentCount;

  @HiveField(5)
  final String paymentFrequency;

  @HiveField(6)
  final DateTime firstDueDate;

  @HiveField(7)
  final String? interestPolicyId;

  @HiveField(8)
  final String lifecycleState;

  @HiveField(9)
  final String? predecessorContractId;

  @HiveField(10)
  final DateTime effectiveDate;

  @HiveField(11)
  final DateTime createdAt;

  const FinancingContract({
    required this.contractId,
    required this.liabilityAccountId,
    required this.originReference,
    required this.principalValue,
    required this.installmentCount,
    required this.paymentFrequency,
    required this.firstDueDate,
    required this.lifecycleState,
    required this.effectiveDate,
    required this.createdAt,
    this.interestPolicyId,
    this.predecessorContractId,
  });

  Money get principal => Money.parse(principalValue);

  FinancingContract copyWith({
    String? lifecycleState,
    String? predecessorContractId,
    DateTime? effectiveDate,
  }) {
    return FinancingContract(
      contractId: contractId,
      liabilityAccountId: liabilityAccountId,
      originReference: originReference,
      principalValue: principalValue,
      installmentCount: installmentCount,
      paymentFrequency: paymentFrequency,
      firstDueDate: firstDueDate,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      createdAt: createdAt,
      interestPolicyId: interestPolicyId,
      predecessorContractId:
          predecessorContractId ?? this.predecessorContractId,
    );
  }
}

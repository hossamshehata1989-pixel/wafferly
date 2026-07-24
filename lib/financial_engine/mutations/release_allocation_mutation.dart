import '../planning/financial_mutation.dart';

final class ReleaseAllocationMutation extends FinancialMutation {
  final String goalId;
  final String accountId;
  final double amount;

  const ReleaseAllocationMutation({
    required this.goalId,
    required this.accountId,
    required this.amount,
  });
}

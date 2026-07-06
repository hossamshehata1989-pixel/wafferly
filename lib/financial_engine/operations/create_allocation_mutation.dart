import '../planning/financial_mutation.dart';

final class CreateAllocationMutation extends DomainMutation {
  final String accountId;
  final String goalId;
  final double amount;

  const CreateAllocationMutation({
    required this.accountId,
    required this.goalId,
    required this.amount,
  });
}

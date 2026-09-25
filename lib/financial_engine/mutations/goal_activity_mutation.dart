import '../../core/money/money.dart';
import '../planning/financial_mutation.dart';

final class GoalActivityMutation extends FinancialMutation {
  final String goalId;
  final String sourceAccountId;
  final String destinationAccountId;
  final Money amount;
  final String activityType;

  const GoalActivityMutation({
    required this.goalId,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amount,
    required this.activityType,
  });
}

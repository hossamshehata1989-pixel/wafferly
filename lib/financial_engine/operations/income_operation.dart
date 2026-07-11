import '../resolution/resolution.dart';
import 'financial_operation.dart';
import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';

final class IncomeOperation extends FinancialOperation {
  final String destinationAccountId;
  final double amount;
  final String categoryId;
  final String? note;
  final DateTime occurredAt;

  const IncomeOperation({
    required this.destinationAccountId,
    required this.amount,
    required this.categoryId,
    required this.occurredAt,
    this.note,
    super.resolution,
  });

  @override
  IncomeOperation resolve(Resolution resolution) {
    return IncomeOperation(
      destinationAccountId: destinationAccountId,
      amount: amount,
      categoryId: categoryId,
      occurredAt: occurredAt,
      note: note,
      resolution: resolution,
    );
  }

  @override
  PlanningContext createPlanningContext({
    required NormalizedIntent intent,
    required List<FinancialConstraint> constraints,
  }) {
    throw UnimplementedError(
      'IncomeOperation has not been migrated to the Financial Command Model yet.',
    );
  }
}

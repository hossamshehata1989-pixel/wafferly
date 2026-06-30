import '../resolution/resolution.dart';
import 'financial_operation.dart';

class ExpenseOperation extends FinancialOperation {
  final String sourceAccountId;

  final double amount;

  final String categoryId;

  final String? note;

  final DateTime occurredAt;

  const ExpenseOperation({
    required this.sourceAccountId,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.occurredAt,
    super.resolution,
  });

  @override
  ExpenseOperation resolve(Resolution resolution) {
    return ExpenseOperation(
      sourceAccountId: sourceAccountId,
      amount: amount,
      categoryId: categoryId,
      note: note,
      occurredAt: occurredAt,
      resolution: resolution,
    );
  }
}

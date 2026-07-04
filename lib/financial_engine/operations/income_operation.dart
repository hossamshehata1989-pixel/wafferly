import '../resolution/resolution.dart';
import 'financial_operation.dart';

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
}

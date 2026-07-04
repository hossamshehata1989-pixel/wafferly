import '../resolution/resolution.dart';
import 'financial_operation.dart';

final class TransferOperation extends FinancialOperation {
  final String sourceAccountId;
  final String destinationAccountId;
  final double amount;
  final String? note;
  final DateTime occurredAt;

  const TransferOperation({
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amount,
    required this.occurredAt,
    this.note,
    super.resolution,
  });

  @override
  TransferOperation resolve(Resolution resolution) {
    return TransferOperation(
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      amount: amount,
      occurredAt: occurredAt,
      note: note,
      resolution: resolution,
    );
  }
}

import '../resolution/resolution.dart';
import 'financial_operation.dart';

class CommitmentPaymentOperation extends FinancialOperation {
  final String sourceAccountId;

  final String commitmentId;

  final double amount;

  final DateTime occurredAt;

  const CommitmentPaymentOperation({
    required this.sourceAccountId,
    required this.commitmentId,
    required this.amount,
    required this.occurredAt,
    super.resolution,
  });

  @override
  CommitmentPaymentOperation resolve(Resolution resolution) {
    return CommitmentPaymentOperation(
      sourceAccountId: sourceAccountId,
      commitmentId: commitmentId,
      amount: amount,
      occurredAt: occurredAt,
      resolution: resolution,
    );
  }
}

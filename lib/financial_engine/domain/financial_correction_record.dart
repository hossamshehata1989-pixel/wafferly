import 'financial_transaction_record.dart';

/// Immutable financial write model describing a correction to previously
/// accepted financial truth.
///
/// The original transaction is preserved as [before]. The [after] record is
/// the new materialized transaction truth. The correction itself is the
/// financial write model that explains how the ledger moves from one truth to
/// the other.
final class FinancialCorrectionRecord {
  final String correctionId;
  final String originalTransactionId;
  final FinancialTransactionRecord before;
  final FinancialTransactionRecord after;

  const FinancialCorrectionRecord({
    required this.correctionId,
    required this.originalTransactionId,
    required this.before,
    required this.after,
  });
}

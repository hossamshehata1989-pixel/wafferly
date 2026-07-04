import 'financial_action_type.dart';

/// Canonical, source-independent representation
/// of a financial intent.
final class NormalizedIntent {
  final FinancialActionType action;

  final String sourceAccountId;

  /// Used only by transfer-like operations.
  final String? destinationAccountId;

  /// Used by expense/income operations.
  final String? categoryId;

  final double amount;

  const NormalizedIntent({
    required this.action,
    required this.amount,
    required this.sourceAccountId,
    this.destinationAccountId,
    this.categoryId,
  });
}

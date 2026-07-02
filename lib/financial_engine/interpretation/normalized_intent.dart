import 'financial_action_type.dart';

/// Canonical, source-independent representation
/// of a financial intent.
///
/// The model intentionally starts small and evolves
/// only when new pipeline stages require additional
/// information.
final class NormalizedIntent {
  final FinancialActionType action;

  final double amount;

  final String sourceAccountId;

  const NormalizedIntent({
    required this.action,
    required this.amount,
    required this.sourceAccountId,
  });
}

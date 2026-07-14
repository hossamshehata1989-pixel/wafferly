import 'financial_action_type.dart';
import '../resolution/resolution.dart';

/// Canonical, source-independent representation
/// of a financial intent.
final class NormalizedIntent {
  final FinancialActionType action;

  final String sourceAccountId;

  /// Used only by transfer-like operations.
  final String? destinationAccountId;

  /// Used by expense/income operations.
  final String? categoryId;

  final String? actorMemberId;
  final bool isExceptional;

  /// Used only by goal operations.
  final String? goalId;

  final double amount;
  final Resolution resolution;

  const NormalizedIntent({
    required this.action,
    required this.amount,
    required this.sourceAccountId,
    this.destinationAccountId,
    this.categoryId,
    this.goalId,

    this.actorMemberId,
    this.isExceptional = false,

    required this.resolution,
  });
}

import '../../core/money/money.dart';
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

  /// Used by opening-balance genesis and balance-reconciliation operations.
  final bool isLiability;

  final Money amount;

  /// Optional currency carried by operations whose domain guard needs to
  /// validate that entered money matches the participating accounts.
  final String? currencyCode;

  final Resolution resolution;

  const NormalizedIntent({
    required this.action,
    required this.amount,
    required this.sourceAccountId,
    this.currencyCode,
    this.destinationAccountId,
    this.categoryId,
    this.goalId,
    this.actorMemberId,
    this.isExceptional = false,
    this.isLiability = false,
    required this.resolution,
  });
}

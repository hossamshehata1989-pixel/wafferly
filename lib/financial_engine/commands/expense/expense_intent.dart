/// Represents the financial intent behind an expense.
///
/// This object contains only data that can affect
/// financial decisions, balances, journals,
/// or execution planning.
///
/// ADR-0011:
/// - Financial Truth starts here.
/// - No UI concerns.
/// - No execution concerns.
/// - No persistence concerns.
final class ExpenseIntent {
  /// Source account that will be debited.
  final String sourceAccountId;

  /// Expense amount.
  final double amount;

  /// Financial category.
  ///
  /// This is the category used by the Financial Engine
  /// (currently Main Category according to ADR-0010).
  final String categoryId;

  /// Whether this expense is exceptional.
  ///
  /// This affects Policy and Planning,
  /// therefore it belongs to the Intent.
  final bool isExceptional;

  final String? actorMemberId;

  const ExpenseIntent({
    required this.sourceAccountId,
    required this.amount,
    required this.categoryId,
    required this.isExceptional,
    this.actorMemberId,
  });
}

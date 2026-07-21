/// Represents the financial transaction produced by the Financial Planner.
///
/// This is a Domain Value Object owned by the Financial Engine.
///
/// It represents the final financial event before persistence.
///
/// It is NOT:
/// - a persistence entity
/// - a Hive model
/// - a Supabase model
/// - a DTO
///
/// ADR-0013
final class FinancialTransactionRecord {
  /// Unique transaction identifier.
  final String transactionId;

  /// Transaction type.
  ///
  /// expense
  /// income
  /// transfer
  final String type;

  /// Account money moved from.
  ///
  /// Null for Income.
  final String? fromAccountId;

  /// Account money moved to.
  ///
  /// Null for Expense.
  final String? toAccountId;

  /// Main category.

  /// Required for expense and income.
  /// Null for transfers.
  ///
  final String? categoryId;

  /// Optional sub-category.
  final String? subCategoryId;

  /// Transaction amount.
  final double amount;

  /// Currency.
  final String currencyCode;

  /// Payment method.
  final String paymentMethod;

  /// Business event date.
  final DateTime occurredAt;

  /// Optional note.
  final String? note;

  /// Exceptional transaction.
  final bool isExceptional;

  /// Source channel.
  ///
  /// manual
  /// sms
  /// ocr
  /// api
  final String source;

  /// Actor member.
  final String? actorMemberId;

  const FinancialTransactionRecord({
    required this.transactionId,
    required this.type,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.subCategoryId,
    required this.amount,
    required this.currencyCode,
    required this.paymentMethod,
    required this.occurredAt,
    this.note,
    required this.isExceptional,
    required this.source,
    this.actorMemberId,
  });
}

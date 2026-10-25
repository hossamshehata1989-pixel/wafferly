import '../../../core/money/money.dart';

/// Domain intent for charging a purchase to a Credit Card liability account.
final class CreditCardChargeIntent {
  final String creditCardAccountId;
  final String categoryId;
  final String? subCategoryId;
  final Money amount;
  final bool isExceptional;
  final String? actorMemberId;

  const CreditCardChargeIntent({
    required this.creditCardAccountId,
    required this.categoryId,
    this.subCategoryId,
    required this.amount,
    this.isExceptional = false,
    this.actorMemberId,
  });
}

import 'package:hive/hive.dart';

import '../../core/money/money.dart';

part 'credit_card_profile.g.dart';

/// Credit-card-specific configuration linked to a real liability Account.
///
/// The profile deliberately does NOT store balance or available credit.
/// Financial position remains owned by the linked liability account.
@HiveType(typeId: 100)
final class CreditCardProfile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  /// Maximum permitted credit exposure.
  /// Stored as a canonical decimal string at the Hive boundary.
  @HiveField(2)
  final String creditLimitValue;

  /// Presentation/configuration only; financial truth remains on the Account.
  @HiveField(3)
  final String cardKind;

  /// Optional card-network label, e.g. Visa or Mastercard.
  @HiveField(4)
  final String? cardNetwork;

  /// Optional statement closing day of month (1-31).
  @HiveField(5)
  final int? statementDay;

  /// Optional payment due day of month (1-31).
  @HiveField(6)
  final int? paymentDueDay;

  /// Optional linked debit-card Account id used for payment setup.
  @HiveField(7)
  final String? linkedDebitCardAccountId;

  /// Optional annual card fee. Metadata only; no financial transaction is
  /// created when the card is created.
  @HiveField(8)
  final String? annualFeeValue;

  /// Optional visual card design identifier used by the presentation layer.
  @HiveField(9)
  final String cardVisual;

  const CreditCardProfile({
    required this.id,
    required this.accountId,
    required this.creditLimitValue,
    this.cardKind = 'physical',
    this.cardNetwork,
    this.statementDay,
    this.paymentDueDay,
    this.linkedDebitCardAccountId,
    this.annualFeeValue,
    this.cardVisual = 'classic',
  });

  factory CreditCardProfile.fromMoney({
    required String id,
    required String accountId,
    required Money creditLimit,
    String cardKind = 'physical',
    String? cardNetwork,
    int? statementDay,
    int? paymentDueDay,
    String? linkedDebitCardAccountId,
    Money? annualFee,
    String cardVisual = 'classic',
  }) {
    if (creditLimit < Money.zero) {
      throw ArgumentError.value(
        creditLimit,
        'creditLimit',
        'Credit limit cannot be negative.',
      );
    }

    if (annualFee != null && annualFee < Money.zero) {
      throw ArgumentError.value(
        annualFee,
        'annualFee',
        'Annual fee cannot be negative.',
      );
    }

    return CreditCardProfile(
      id: id,
      accountId: accountId,
      creditLimitValue: creditLimit.toString(),
      cardKind: cardKind,
      cardNetwork: cardNetwork,
      statementDay: statementDay,
      paymentDueDay: paymentDueDay,
      linkedDebitCardAccountId: linkedDebitCardAccountId,
      annualFeeValue: annualFee?.toString(),
      cardVisual: cardVisual,
    );
  }

  /// Domain-facing credit limit. Persistence stores the canonical decimal
  /// representation in [creditLimitValue] so Money remains persistence-agnostic.
  Money get creditLimit => Money.parse(creditLimitValue);

  Money? get annualFee =>
      annualFeeValue == null ? null : Money.parse(annualFeeValue!);
}

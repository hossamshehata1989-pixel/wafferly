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

  const CreditCardProfile({
    required this.id,
    required this.accountId,
    required this.creditLimitValue,
  });

  factory CreditCardProfile.fromMoney({
    required String id,
    required String accountId,
    required Money creditLimit,
  }) {
    if (creditLimit < Money.zero) {
      throw ArgumentError.value(
        creditLimit,
        'creditLimit',
        'Credit limit cannot be negative.',
      );
    }

    return CreditCardProfile(
      id: id,
      accountId: accountId,
      creditLimitValue: creditLimit.toString(),
    );
  }

  /// Domain-facing credit limit. Persistence stores the canonical decimal
  /// representation in [creditLimitValue] so Money remains persistence-agnostic.
  Money get creditLimit => Money.parse(creditLimitValue);
}

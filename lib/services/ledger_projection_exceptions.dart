import '../models/enums/ledger_account_type.dart';

/// Base exception for a Ledger projection that cannot be built safely.
sealed class LedgerProjectionException implements Exception {
  const LedgerProjectionException();
}

/// Raised when a category has no persisted Ledger account mapping.
final class MissingCategoryLedgerMappingException
    extends LedgerProjectionException {
  final String categoryId;
  final LedgerAccountType expectedType;

  const MissingCategoryLedgerMappingException({
    required this.categoryId,
    required this.expectedType,
  });

  @override
  String toString() =>
      'Missing Ledger mapping for category "$categoryId" '
      '(expected ${expectedType.name} account).';
}

/// Raised when a category points to an account of the wrong Ledger type.
final class InvalidCategoryLedgerMappingException
    extends LedgerProjectionException {
  final String categoryId;
  final String accountId;
  final LedgerAccountType expectedType;
  final LedgerAccountType actualType;
  final bool actualIsSystem;

  const InvalidCategoryLedgerMappingException({
    required this.categoryId,
    required this.accountId,
    required this.expectedType,
    required this.actualType,
    required this.actualIsSystem,
  });

  @override
  String toString() =>
      'Ledger mapping for category "$categoryId" points to account '
      '"$accountId" (type ${actualType.name}, system=$actualIsSystem); '
      'a system ${expectedType.name} account is required.';
}

/// Raised instead of silently accepting a transaction type without a Ledger rule.
final class UnsupportedLedgerTransactionTypeException
    extends LedgerProjectionException {
  final String transactionType;

  const UnsupportedLedgerTransactionTypeException(this.transactionType);

  @override
  String toString() =>
      'Ledger projection is not defined for transaction type '
      '"$transactionType".';
}

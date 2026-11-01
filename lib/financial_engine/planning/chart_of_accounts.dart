import '../../constants/ledger_system_account_ids.dart';
import 'account_mapping.dart';

final class ChartOfAccounts {
  static const openingBalanceEquityAccountId =
      LedgerSystemAccountIds.openingBalanceEquity;
  static const balanceReconciliationEquityAccountId =
      LedgerSystemAccountIds.balanceReconciliationEquity;

  final List<AccountMapping> mappings;

  const ChartOfAccounts({this.mappings = const []});

  /// Returns the explicit accounting-intent account for a category.
  ///
  /// Missing mappings are not inferred: the planner must reject the operation
  /// rather than silently treating an income category as an expense.
  String? accountForCategory(String categoryId) {
    final matching = mappings
        .where((mapping) => mapping.categoryId == categoryId)
        .toList(growable: false);
    if (matching.length > 1) {
      throw DuplicateChartOfAccountsMappingException(
        categoryId,
        matching.length,
      );
    }
    if (matching.isEmpty) return null;
    return matching.single.accountId;
  }

  String requireAccountForCategory(String categoryId) {
    final accountId = accountForCategory(categoryId);
    if (accountId == null || accountId.trim().isEmpty) {
      throw MissingChartOfAccountsMappingException(categoryId);
    }
    return accountId;
  }
}

/// A category must have an explicit accounting-intent mapping before the
/// Financial Planner can create journal lines.
final class MissingChartOfAccountsMappingException implements Exception {
  final String categoryId;

  const MissingChartOfAccountsMappingException(this.categoryId);

  @override
  String toString() =>
      'No Chart of Accounts mapping found for category "$categoryId".';
}


/// A category must resolve to exactly one accounting-intent account.
final class DuplicateChartOfAccountsMappingException implements Exception {
  final String categoryId;
  final int mappingCount;

  const DuplicateChartOfAccountsMappingException(
    this.categoryId,
    this.mappingCount,
  );

  @override
  String toString() =>
      'Category "$categoryId" has $mappingCount Chart of Accounts mappings.';
}

// Sprint 3C — Category Ledger Mapping
import '../models/ledger_account.dart';
import '../models/enums/ledger_account_type.dart';
import 'ledger_account_service.dart';
import 'ledger_projection_exceptions.dart';

class CategoryLedgerMapper {
  CategoryLedgerMapper({
    LedgerAccount? Function(String categoryId)? lookup,
  }) : _lookup = lookup ?? LedgerAccountService().getByCategoryId;

  final LedgerAccount? Function(String categoryId) _lookup;

  /// Returns the persisted Ledger account ID, or null when no mapping exists.
  /// A mapping to the wrong account type is always rejected.
  String? getLedgerAccountIdForCategory(
    String categoryId, {
    LedgerAccountType? expectedType,
  }) {
    final account = _lookup(categoryId);
    if (account == null) return null;

    if (expectedType != null &&
        (account.type != expectedType || !account.isSystem)) {
      throw InvalidCategoryLedgerMappingException(
        categoryId: categoryId,
        accountId: account.id,
        expectedType: expectedType,
        actualType: account.type,
        actualIsSystem: account.isSystem,
      );
    }

    return account.id;
  }
}

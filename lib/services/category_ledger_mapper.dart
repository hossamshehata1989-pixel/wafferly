// lib/services/category_ledger_mapper.dart
// Sprint 3C — Category Ledger Mapping
import 'ledger_account_service.dart';

class CategoryLedgerMapper {
  final LedgerAccountService _ledgerService = LedgerAccountService();

  /// Returns LedgerAccount ID for a given categoryId, or null if not found.
  String? getLedgerAccountIdForCategory(String categoryId) {
    final account = _ledgerService.getByCategoryId(categoryId);
    return account?.id;
  }
}

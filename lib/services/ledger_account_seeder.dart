// Sprint 3C — Category Ledger Mapping
import 'package:hive/hive.dart';
import '../models/ledger_account.dart';
import '../models/enums/ledger_account_type.dart';
import '../config/category_config.dart';
import 'ledger_account_service.dart';

class LedgerAccountSeeder {
  final LedgerAccountService _service = LedgerAccountService();

  /// Seeds system ledger accounts for all expense and income categories.
  /// Idempotent: safe to call multiple times.
  Future<void> seedIfNeeded() async {
    final existing = _service.getAllAccounts();
    final existingIds = existing.map((a) => a.categoryId).toSet();

    // Create expense ledger accounts
    for (final category in expenseCategories) {
      if (!existingIds.contains(category.id)) {
        await _service.createAccount(
          name: _generateAccountName(category.id),
          type: LedgerAccountType.expense,
          categoryId: category.id,
          isSystem: true,
        );
        print("✅ Seeded expense ledger account for category: ${category.id}");
      }
    }

    // Create income ledger accounts
    for (final category in incomeCategories) {
      if (!existingIds.contains(category.id)) {
        await _service.createAccount(
          name: _generateAccountName(category.id),
          type: LedgerAccountType.income,
          categoryId: category.id,
          isSystem: true,
        );
        print("✅ Seeded income ledger account for category: ${category.id}");
      }
    }
  }

  String _generateAccountName(String categoryId) {
    // Human-readable name (can be improved with localization later)
    return "ledger.$categoryId";
  }
}
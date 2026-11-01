// Sprint 3C — Category Ledger Mapping
import '../models/enums/ledger_account_type.dart';
import '../constants/ledger_system_account_ids.dart';
import '../config/category_config.dart';
import 'ledger_account_service.dart';

class LedgerAccountSeeder {
  final LedgerAccountService _service = LedgerAccountService();

  /// Seeds every configured category mapping and the canonical system
  /// accounts. Idempotent: safe to call repeatedly.
  Future<void> seedIfNeeded() async {
    for (final category in expenseCategories) {
      await _ensureCategoryAccount(
        category,
        LedgerAccountType.expense,
      );
    }

    for (final category in incomeCategories) {
      await _ensureCategoryAccount(
        category,
        LedgerAccountType.income,
      );
    }

    await _service.ensureSystemAccount(
      id: LedgerSystemAccountIds.openingBalanceEquity,
      name: 'ledger.opening_balance_equity',
      type: LedgerAccountType.equity,
    );
    await _service.ensureSystemAccount(
      id: LedgerSystemAccountIds.balanceReconciliationEquity,
      name: 'ledger.balance_reconciliation_equity',
      type: LedgerAccountType.equity,
    );
  }

  Future<void> _ensureCategoryAccount(
    CategoryConfig category,
    LedgerAccountType expectedType,
  ) async {
    final matches = _service
        .getAllAccounts()
        .where((account) => account.categoryId == category.id)
        .toList(growable: false);

    if (matches.length > 1) {
      throw StateError(
        'Category "${category.id}" has multiple Ledger account mappings.',
      );
    }

    if (matches.isNotEmpty) {
      final account = matches.single;
      if (!account.isSystem || account.type != expectedType) {
        throw StateError(
          'Category "${category.id}" has an incompatible Ledger mapping '
          '(expected system ${expectedType.name} account).',
        );
      }
      return;
    }

    await _service.createAccount(
      name: _generateAccountName(category.id),
      type: expectedType,
      categoryId: category.id,
      isSystem: true,
    );
  }

  String _generateAccountName(String categoryId) {
    return 'ledger.$categoryId';
  }
}

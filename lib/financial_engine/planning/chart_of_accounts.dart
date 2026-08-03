import 'package:flutter/foundation.dart';
import 'account_mapping.dart';

final class ChartOfAccounts {
  static const openingBalanceEquityAccountId = 'opening_balance_equity';

  final List<AccountMapping> mappings;

  const ChartOfAccounts({this.mappings = const []});

  String? accountForCategory(String categoryId) {
    for (final mapping in mappings) {
      if (mapping.categoryId == categoryId) {
        return mapping.accountId;
      }
    }

    // ============================================================
    // TODO(ADR-0010)
    //
    // Temporary implementation.
    //
    // Remove after LedgerAccountResolver integration.
    //
    // Sprint 6.
    // ============================================================

    debugPrint(
      '[TEMP] No mapping found for "$categoryId". '
      'Using default expense ledger.',
    );

    return 'expense_default';
  }
}

/// Stable identifiers for system-owned Ledger accounts.
///
/// These IDs are persisted and must not be replaced with generated IDs.
abstract final class LedgerSystemAccountIds {
  static const String openingBalanceEquity = 'opening_balance_equity';
  static const String balanceReconciliationEquity =
      'balance_reconciliation_equity';
}

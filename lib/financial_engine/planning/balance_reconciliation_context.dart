import '../commands/balance_reconciliation/reconciliation_reason.dart';

final class BalanceReconciliationContext {
  final String accountId;
  final double systemBalance;
  final double observedBalance;
  final bool isLiability;
  final ReconciliationReason reason;

  const BalanceReconciliationContext({
    required this.accountId,
    required this.systemBalance,
    required this.observedBalance,
    required this.isLiability,
    required this.reason,
  });

  double get difference => observedBalance - systemBalance;
}

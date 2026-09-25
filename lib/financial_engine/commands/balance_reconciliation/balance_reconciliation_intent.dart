import '../../../core/money/money.dart';
import 'reconciliation_reason.dart';

/// Financial intent for reconciling an observed account balance with the
/// balance currently derived by Wafferly.
///
/// The account balance itself is never mutated. The difference becomes a
/// financial operation against the dedicated reconciliation equity account.
final class BalanceReconciliationIntent {
  final String accountId;
  final Money systemBalance;
  final Money observedBalance;
  final bool isLiability;
  final ReconciliationReason reason;

  const BalanceReconciliationIntent({
    required this.accountId,
    required this.systemBalance,
    required this.observedBalance,
    required this.isLiability,
    required this.reason,
  });

  Money get difference => observedBalance - systemBalance;
}

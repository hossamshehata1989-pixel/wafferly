import 'balance_policy.dart';
import 'financial_policy.dart';

final class PolicyRegistry {
  const PolicyRegistry();

  List<FinancialPolicy> get policies => const [BalancePolicy()];
}

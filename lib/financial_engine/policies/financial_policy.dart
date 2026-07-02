import '../interpretation/normalized_intent.dart';
import 'policy_result.dart';

abstract interface class FinancialPolicy {
  const FinancialPolicy();

  Future<PolicyResult> evaluate(NormalizedIntent intent);
}

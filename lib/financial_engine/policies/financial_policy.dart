import '../operations/financial_operation.dart';
import 'policy_result.dart';

abstract interface class FinancialPolicy {
  const FinancialPolicy();

  Future<PolicyResult> evaluate(FinancialOperation operation);
}

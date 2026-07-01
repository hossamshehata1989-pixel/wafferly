import '../operations/financial_operation.dart';
import 'policy_registry.dart';
import 'policy_result.dart';

final class PolicyPipeline {
  final PolicyRegistry registry;

  const PolicyPipeline({this.registry = const PolicyRegistry()});

  Future<PolicyResult> evaluate(FinancialOperation operation) async {
    for (final policy in registry.policies) {
      final result = await policy.evaluate(operation);

      if (result is! PolicyPassed) {
        return result;
      }
    }

    return const PolicyPassed();
  }
}

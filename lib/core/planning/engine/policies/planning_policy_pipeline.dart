import '../planning_execution_context.dart';
import 'planning_policy.dart';

/// ===============================================================
/// PlanningPolicyPipeline
/// ===============================================================
///
/// Executes all registered planning policies sequentially.
///
/// Each policy may enrich the execution context.
///
/// ===============================================================
final class PlanningPolicyPipeline {
  const PlanningPolicyPipeline({required this.policies});

  final List<PlanningPolicy> policies;

  Future<PlanningExecutionContext> apply(
    PlanningExecutionContext context,
  ) async {
    var current = context;

    for (final policy in policies) {
      current = await policy.apply(current);
    }

    return current;
  }
}

import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';

final class PlanningContext {
  final NormalizedIntent intent;

  final TransactionMetadata metadata;

  final ExecutionContext executionContext;

  final List<FinancialConstraint> constraints;

  const PlanningContext({
    required this.intent,
    required this.metadata,
    required this.executionContext,

    this.constraints = const [],
  });

  T? constraint<T extends FinancialConstraint>() {
    for (final constraint in constraints) {
      if (constraint is T) {
        return constraint;
      }
    }
    return null;
  }
}

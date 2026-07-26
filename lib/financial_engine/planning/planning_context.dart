import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';
import 'correction_context.dart';
import 'deletion_context.dart';

final class PlanningContext {
  final NormalizedIntent intent;

  final TransactionMetadata metadata;

  final ExecutionContext executionContext;

  final List<FinancialConstraint> constraints;

  final CorrectionContext? correction;

  final DeletionContext? deletion;

  const PlanningContext({
    required this.intent,
    required this.metadata,
    required this.executionContext,
    this.constraints = const [],
    this.correction,
    this.deletion,
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

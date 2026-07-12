import '../commands/income/income_intent.dart';
import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

/// Rich Income Operation.
///
/// Carries the complete business operation through the Financial Engine.
///
/// ADR-0011
/// ADR-0013
final class IncomeOperation extends FinancialOperation {
  /// Financial intent.
  final IncomeIntent intent;

  /// Transaction metadata.
  final TransactionMetadata metadata;

  /// Execution context.
  final ExecutionContext context;

  const IncomeOperation({
    required this.intent,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  IncomeOperation resolve(Resolution resolution) {
    return IncomeOperation(
      intent: intent,
      metadata: metadata,
      context: context,
      resolution: resolution,
    );
  }

  @override
  PlanningContext createPlanningContext({
    required NormalizedIntent intent,
    required List<FinancialConstraint> constraints,
  }) {
    return PlanningContext(
      intent: intent,
      metadata: metadata,
      executionContext: context,
      constraints: constraints,
    );
  }
}

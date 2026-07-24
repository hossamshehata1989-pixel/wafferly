import '../commands/correction/correction_intent.dart';
import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/correction_context.dart';
import '../planning/planning_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

final class CorrectionOperation extends FinancialOperation {
  final CorrectionIntent intent;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const CorrectionOperation({
    required this.intent,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  CorrectionOperation resolve(Resolution resolution) {
    return CorrectionOperation(
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
      correction: CorrectionContext(
        transactionId: this.intent.transactionId,
      ),
    );
  }
}
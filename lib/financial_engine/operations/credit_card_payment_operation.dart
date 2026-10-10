import '../../core/money/money.dart';
import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

/// Explicit settlement of a Credit Card liability from an Asset Account.
///
/// This is intentionally distinct from a CreditCardChargeOperation. It enters
/// the canonical Financial Operation Engine and does not mutate persistence.
final class CreditCardPaymentOperation extends FinancialOperation {
  final String sourceAssetAccountId;
  final String creditCardAccountId;
  final Money amount;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const CreditCardPaymentOperation({
    required this.sourceAssetAccountId,
    required this.creditCardAccountId,
    required this.amount,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  CreditCardPaymentOperation resolve(Resolution resolution) {
    return CreditCardPaymentOperation(
      sourceAssetAccountId: sourceAssetAccountId,
      creditCardAccountId: creditCardAccountId,
      amount: amount,
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
      executionContext: ExecutionContext(
        idempotencyKey: context.idempotencyKey,
        commitmentId: context.commitmentId,
        scheduleRuleId: context.scheduleRuleId,
        occurrenceId: context.occurrenceId,
        actorMemberId: context.actorMemberId,
        source: context.source,
        commandType: context.commandType,
      ),
      constraints: constraints,
    );
  }
}

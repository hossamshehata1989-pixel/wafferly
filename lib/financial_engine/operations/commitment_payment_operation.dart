import '../../core/money/money.dart';
import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

final class CommitmentPaymentOperation extends FinancialOperation {
  final String sourceAccountId;
  final String liabilityAccountId;
  final String commitmentId;
  final Money amount;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const CommitmentPaymentOperation({
    required this.sourceAccountId,
    required this.liabilityAccountId,
    required this.commitmentId,
    required this.amount,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  CommitmentPaymentOperation resolve(Resolution resolution) {
    return CommitmentPaymentOperation(
      sourceAccountId: sourceAccountId,
      liabilityAccountId: liabilityAccountId,
      commitmentId: commitmentId,
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
        commitmentId: commitmentId,
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
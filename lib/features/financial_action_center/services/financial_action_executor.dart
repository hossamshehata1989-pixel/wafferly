import '../../../core/money/money.dart';
import 'package:flutter/material.dart';

import '../../../models/enums/scheduled_action_kind.dart';
import '../../../models/scheduled_action_execution_context.dart';

import '../../../financial_engine/commands/shared/transaction_metadata.dart';
import '../../../financial_engine/execution_context/execution_context.dart';
import '../../../financial_engine/operations/commitment_payment_operation.dart';
import '../../../financial_engine/engine/financial_operation_engine.dart';
import '../../../financial_engine/results/operation_result.dart';

import '../../../services/schedule_occurrence_service.dart';

class FinancialActionExecutor {
  final FinancialOperationEngine engine;
  final ScheduleOccurrenceService occurrenceService;

  const FinancialActionExecutor({
    required this.engine,
    required this.occurrenceService,
  });

  Future<bool> execute(
    BuildContext context,
    ScheduledActionExecutionContext action,
  ) async {
    switch (action.action.kind) {
      case ScheduledActionKind.liabilityPayment:
        return _executeLiabilityPayment(action);

      case ScheduledActionKind.expense:
      case ScheduledActionKind.income:
      case ScheduledActionKind.transfer:
      case ScheduledActionKind.goalContribution:
      case ScheduledActionKind.budgetReset:
      case ScheduledActionKind.investment:
        debugPrint(
          'FinancialActionExecutor: ${action.action.kind.name} '
          'is not wired to the Financial Engine yet.',
        );
        return false;
    }
  }

  Future<bool> _executeLiabilityPayment(
    ScheduledActionExecutionContext action,
  ) async {
    final sourceAccountId = action.commitment.sourceAccountId;
    final liabilityAccountId = action.commitment.liabilityAccountId;

    if (sourceAccountId == null || sourceAccountId.isEmpty) {
      debugPrint('Commitment payment rejected: source account is missing.');
      return false;
    }

    if (liabilityAccountId == null || liabilityAccountId.isEmpty) {
      debugPrint('Commitment payment rejected: liability account is missing.');
      return false;
    }

    final executionContext = ExecutionContext(
      idempotencyKey: 'scheduled-commitment:${action.occurrence.id}',
      commitmentId: action.commitment.id,
      scheduleRuleId: action.scheduleRule.id,
      occurrenceId: action.occurrence.id,
      source: 'scheduled',
      commandType: 'CommitmentPaymentOperation',
    );

    final operation = CommitmentPaymentOperation(
      sourceAccountId: sourceAccountId,
      liabilityAccountId: liabilityAccountId,
      commitmentId: action.commitment.id,
      amount: Money.fromDouble(action.commitment.amount.toDouble()),
      metadata: TransactionMetadata(
        occurredAt: DateTime.now(),
        note: action.commitment.notes,
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: executionContext,
    );

    debugPrint(
      'Executing liability payment through FinancialOperationEngine: '
      '${action.commitment.id}',
    );

    final result = await engine.execute(
      operation,
      executionContext,
    );

    if (result is! OperationSucceeded) {
      debugPrint(
        'Commitment payment failed: ${result.runtimeType}',
      );
      return false;
    }

    await occurrenceService.completeOccurrence(action.occurrence);

    final latestRule =
        occurrenceService.ruleService.getRule(action.scheduleRule.id) ??
        action.scheduleRule;

    await occurrenceService.advanceRuleAfterOccurrence(
      latestRule,
      action.occurrence,
    );

    debugPrint(
      'Commitment payment succeeded: ${action.commitment.id}',
    );
    return true;
  }
}

import '../financial_engine/results/operation_result.dart';
import '../models/scheduled_action_execution_context.dart';
import 'schedule_occurrence_service.dart';
import 'scheduled_execution_journal.dart';

/// Coordinates financial execution with scheduling state.
///
/// The financial engine remains the only owner of financial truth. This
/// coordinator provides observational atomicity across the financial and
/// scheduling boundaries using a durable journal plus the financial
/// operation's stable idempotency key.
class ScheduledFinancialExecutionCoordinator {
  final ScheduleOccurrenceService occurrenceService;
  final ScheduledExecutionJournal journal;

  const ScheduledFinancialExecutionCoordinator({
    required this.occurrenceService,
    required this.journal,
  });

  Future<bool> execute({
    required ScheduledActionExecutionContext action,
    required String idempotencyKey,
    required Future<OperationResult> Function() executeFinancialOperation,
  }) async {
    final occurrenceId = action.occurrence.id;
    final existing = journal.get(occurrenceId);
    final existingState = existing?['state'];

    if (existingState == ScheduledExecutionJournal.stateCompleted) {
      return true;
    }

    // A prior attempt may have created the financial effect successfully but
    // failed while committing scheduling state. Never execute the financial
    // operation a second time; resume the scheduling transition instead.
    final financialAlreadySucceeded =
        existingState == ScheduledExecutionJournal.stateFinancialSucceeded;

    if (!financialAlreadySucceeded) {
      await journal.markExecuting(
        occurrenceId: occurrenceId,
        idempotencyKey: idempotencyKey,
      );

      final result = await executeFinancialOperation();

      if (result is! OperationSucceeded) {
        await journal.markFailed(
          occurrenceId: occurrenceId,
          idempotencyKey: idempotencyKey,
          error: result.runtimeType,
        );
        return false;
      }

      await journal.markFinancialSucceeded(
        occurrenceId: occurrenceId,
        idempotencyKey: idempotencyKey,
        transactionIds: result.summary.createdTransactionIds,
      );
    }

    try {
      final completed = await occurrenceService.completeOccurrence(
        action.occurrence,
      );

      final latestRule =
          occurrenceService.ruleService.getRule(action.scheduleRule.id) ??
          action.scheduleRule;

      await occurrenceService.advanceRuleAfterOccurrence(
        latestRule,
        completed,
      );

      await journal.markCompleted(occurrenceId: occurrenceId);
      return true;
    } catch (_) {
      // Keep state at financial_succeeded. A later retry resumes here and
      // cannot create a duplicate financial effect because the same durable
      // idempotency key is retained by the financial engine.
      return false;
    }
  }
}

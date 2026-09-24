import 'package:flutter/foundation.dart';

import '../domain_guard/domain_guard_pipeline.dart';
import '../execution/financial_executor.dart';
import '../execution_context/execution_context.dart';
import '../idempotency/idempotency_guard.dart';
import '../mutations/create_correction_mutation.dart';
import '../mutations/create_transaction_mutation.dart';
import '../mutations/invalidate_transaction_mutation.dart';
import '../mutations/journal_entry_mutation.dart';
import '../planning/financial_mutation.dart';
import '../ports/traceability_port.dart';
import '../traceability/traceability_record.dart';
import '../integrity/financial_integrity_checker.dart';
import '../interpretation/financial_interpreter.dart';
import '../operations/financial_operation.dart';
import '../planning/financial_planner.dart';
import '../policies/policy_pipeline.dart';
import '../policies/policy_result.dart';
import '../results/operation_result.dart';

final class FinancialOperationEngine {
  final FinancialInterpreter _interpreter;
  final DomainGuardPipeline _domainGuardPipeline;
  final PolicyPipeline _policyPipeline;
  final FinancialPlanner _planner;
  final FinancialIntegrityChecker _integrityChecker;
  final FinancialExecutor _executor;
  final IdempotencyGuard _idempotencyGuard;
  final TraceabilityPort _traceabilityPort;

  const FinancialOperationEngine({
    required FinancialInterpreter interpreter,
    required DomainGuardPipeline domainGuardPipeline,
    required FinancialPlanner planner,
    required FinancialIntegrityChecker integrityChecker,
    required FinancialExecutor executor,
    required IdempotencyGuard idempotencyGuard,
    required TraceabilityPort traceabilityPort,
    PolicyPipeline policyPipeline = const PolicyPipeline(),
  }) : _interpreter = interpreter,
       _domainGuardPipeline = domainGuardPipeline,
       _policyPipeline = policyPipeline,
       _planner = planner,
       _integrityChecker = integrityChecker,
       _executor = executor,
       _idempotencyGuard = idempotencyGuard,
       _traceabilityPort = traceabilityPort;

  Future<OperationResult> execute(
    FinancialOperation operation,
    ExecutionContext context,
  ) async {
    // ====================================================
    // Step 0 — Idempotency
    // ====================================================

    final cached = await _idempotencyGuard.check(context);

    if (cached != null) {
      debugPrint('ENGINE: Idempotency cache hit');
      return cached;
    }

    final startedAt = DateTime.now();

    // ====================================================
    // Step 1 — Interpretation
    // ====================================================

    final intent = _interpreter.interpret(operation);

    debugPrint('ENGINE: Interpreter ✓');

    // ====================================================
    // Step 2 — Domain Guard
    // ====================================================

    final domainResult = await _domainGuardPipeline.validate(intent);

    if (domainResult.hasViolation) {
      final result = DomainViolationResult(reason: domainResult.violation!.reason);
      await _recordTrace(
        operation: operation,
        context: context,
        startedAt: startedAt,
        status: 'domain_violation',
        error: result.reason,
      );
      return result;
    }

    debugPrint('ENGINE: DomainGuard ✓');

    for (final constraint in domainResult.constraints) {
      debugPrint(constraint.runtimeType.toString());
    }

    // ====================================================
    // Step 3 — Policy
    // ====================================================

    try {
      final policyResult = await _policyPipeline.evaluate(
        intent,
        domainResult.constraints,
      );

      debugPrint('ENGINE: Policy result = ${policyResult.runtimeType}');

      if (policyResult is PolicyRejected) {
        final result = OperationRejected(reason: policyResult.reason);
        await _recordTrace(
          operation: operation,
          context: context,
          startedAt: startedAt,
          status: 'rejected',
          error: result.reason,
        );
        return result;
      }

      if (policyResult is PolicyRequiresConfirmation) {
        final result = ConfirmationRequired(options: policyResult.options);
        await _recordTrace(
          operation: operation,
          context: context,
          startedAt: startedAt,
          status: 'confirmation_required',
        );
        return result;
      }

      debugPrint('ENGINE: Policy ✓');

      // ====================================================
      // Step 4 — Planning
      // ====================================================

      final planningContext = operation.createPlanningContext(
        intent: intent,
        constraints: domainResult.constraints,
      );

      final plan = await _planner.build(planningContext);

      debugPrint('ENGINE: Planner ✓');

      // ====================================================
      // Step 5 — Integrity
      // ====================================================

      _integrityChecker.validate(plan);

      debugPrint('ENGINE: Integrity ✓');

      // ====================================================
      // Step 6 — Execution
      // ====================================================

      debugPrint('ENGINE: Executor...');

      final result = await _executor.execute(plan);

      debugPrint('ENGINE RESULT = ${result.runtimeType}');

      if (result is OperationFailed) {
        debugPrint(result.toString());
      }

      if (result is OperationSucceeded) {
        await _idempotencyGuard.remember(context, result);
      }

      await _recordTrace(
        operation: operation,
        context: context,
        startedAt: startedAt,
        status: result is OperationSucceeded ? 'succeeded' : 'failed',
        operationId: plan.operationId,
        transactionIds: _transactionIds(plan.mutations),
        mutationIds: _mutationIds(plan.mutations),
        error: result is OperationFailed ? result.error.toString() : null,
      );

      return result;
    } catch (e, s) {
      debugPrint('POLICY EXCEPTION:');
      debugPrint(e.toString());
      debugPrint(s.toString());

      final result = OperationFailed(error: e.toString());
      await _recordTrace(
        operation: operation,
        context: context,
        startedAt: startedAt,
        status: 'failed',
        error: e.toString(),
      );
      return result;
    }
  }

  Future<void> _recordTrace({
    required FinancialOperation operation,
    required ExecutionContext context,
    required DateTime startedAt,
    required String status,
    String? operationId,
    List<String> transactionIds = const <String>[],
    List<String> mutationIds = const <String>[],
    String? error,
  }) async {
    try {
      await _traceabilityPort.save(
        TraceabilityRecord(
          traceId: 'trace-${context.idempotencyKey}-${startedAt.microsecondsSinceEpoch}',
          operationType: context.commandType ?? operation.runtimeType.toString(),
          operationId: operationId,
          idempotencyKey: context.idempotencyKey,
          status: status,
          actorMemberId: context.actorMemberId,
          source: context.source,
          commitmentId: context.commitmentId,
          scheduleRuleId: context.scheduleRuleId,
          occurrenceId: context.occurrenceId,
          transactionIds: transactionIds,
          mutationIds: mutationIds,
          error: error,
          startedAt: startedAt,
          completedAt: DateTime.now(),
        ),
      );
    } catch (traceError) {
      // Traceability must never turn an already-applied Financial Reality
      // mutation into a reported financial failure. The audit adapter is a
      // separate state boundary; its persistence failure is observable but
      // does not change the financial result.
      debugPrint('TRACEABILITY ERROR: $traceError');
    }
  }

  List<String> _transactionIds(List<FinancialMutation> mutations) {
    final ids = <String>[];
    for (final mutation in mutations) {
      if (mutation is CreateTransactionMutation) {
        ids.add(mutation.record.transactionId);
      } else if (mutation is CreateCorrectionMutation) {
        ids.add(mutation.record.originalTransactionId);
        ids.add(mutation.record.after.transactionId);
      } else if (mutation is InvalidateTransactionMutation) {
        ids.add(mutation.record.originalTransactionId);
      }
    }
    return ids.toSet().toList(growable: false);
  }

  List<String> _mutationIds(List<FinancialMutation> mutations) {
    final ids = <String>[];
    for (final mutation in mutations) {
      if (mutation is CreateCorrectionMutation) {
        ids.add(mutation.record.correctionId);
      } else if (mutation is InvalidateTransactionMutation) {
        ids.add(mutation.record.invalidationId);
      } else if (mutation is JournalEntryMutation) {
        ids.add(mutation.journalEntryId);
      }
    }
    return ids.toSet().toList(growable: false);
  }
}

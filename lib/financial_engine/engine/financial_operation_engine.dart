import 'package:flutter/foundation.dart';

import '../domain_guard/domain_guard_pipeline.dart';
import '../execution/financial_executor.dart';
import '../execution_context/execution_context.dart';
import '../idempotency/financial_operation_fingerprint.dart';
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

  /// Executes a financial operation through the fingerprint-aware guard.
  ///
  /// The guard reservation is created synchronously before store lookup or
  /// financial execution begins. Same-key/same-request calls share one Future.
  Future<OperationResult> execute(
    FinancialOperation operation,
    ExecutionContext context,
  ) async {
    final startedAt = DateTime.now();
    _FinancialOperationExecution? execution;

    try {
      final fingerprint = FinancialOperationFingerprint.compute(
        operation: operation,
        executionContext: context,
      );

      final result = await _idempotencyGuard.run(
        key: context.idempotencyKey,
        requestFingerprint: fingerprint,
        action: () async {
          execution = await _executeOnce(operation: operation);
          return execution!.result;
        },
      );

      // Persist traceability after the Guard has durably remembered a success.
      // A cache hit has no local execution outcome and therefore adds no trace.
      final completedExecution = execution;
      if (completedExecution != null) {
        await _recordTrace(
          operation: operation,
          context: context,
          startedAt: startedAt,
          status: completedExecution.status,
          operationId: completedExecution.operationId,
          transactionIds: completedExecution.transactionIds,
          mutationIds: completedExecution.mutationIds,
          error: completedExecution.error,
        );
      }

      return result;
    } on IdempotencyConflictException catch (error, stackTrace) {
      debugPrint('ENGINE: Idempotency conflict: $error');
      debugPrint(stackTrace.toString());
      await _recordTrace(
        operation: operation,
        context: context,
        startedAt: startedAt,
        status: 'idempotency_conflict',
        operationId: execution?.operationId,
        transactionIds: execution?.transactionIds ?? const <String>[],
        mutationIds: execution?.mutationIds ?? const <String>[],
        error: error.toString(),
      );
      return OperationFailed(error: error.toString());
    } catch (error, stackTrace) {
      debugPrint('ENGINE: Execution boundary exception: $error');
      debugPrint(stackTrace.toString());
      await _recordTrace(
        operation: operation,
        context: context,
        startedAt: startedAt,
        status: 'failed',
        operationId: execution?.operationId,
        transactionIds: execution?.transactionIds ?? const <String>[],
        mutationIds: execution?.mutationIds ?? const <String>[],
        error: error.toString(),
      );
      return OperationFailed(error: error.toString());
    }
  }

  Future<_FinancialOperationExecution> _executeOnce({
    required FinancialOperation operation,
  }) async {
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
      final result = DomainViolationResult(
        reason: domainResult.violation!.reason,
      );
      return _FinancialOperationExecution(
        result: result,
        status: 'domain_violation',
        error: result.reason,
      );
    }

    debugPrint('ENGINE: DomainGuard ✓');

    for (final constraint in domainResult.constraints) {
      debugPrint(constraint.runtimeType.toString());
    }

    // ====================================================
    // Step 3 — Policy, Planning, Integrity and Execution
    // ====================================================

    try {
      final policyResult = await _policyPipeline.evaluate(
        intent,
        domainResult.constraints,
      );

      debugPrint('ENGINE: Policy result = ${policyResult.runtimeType}');

      if (policyResult is PolicyRejected) {
        final result = OperationRejected(reason: policyResult.reason);
        return _FinancialOperationExecution(
          result: result,
          status: 'rejected',
          error: result.reason,
        );
      }

      if (policyResult is PolicyRequiresConfirmation) {
        final result = ConfirmationRequired(options: policyResult.options);
        return _FinancialOperationExecution(
          result: result,
          status: 'confirmation_required',
        );
      }

      debugPrint('ENGINE: Policy ✓');

      final planningContext = operation.createPlanningContext(
        intent: intent,
        constraints: domainResult.constraints,
      );
      final plan = await _planner.build(planningContext);
      debugPrint('ENGINE: Planner ✓');

      _integrityChecker.validate(plan);
      debugPrint('ENGINE: Integrity ✓');

      debugPrint('ENGINE: Executor...');
      final result = await _executor.execute(plan);
      debugPrint('ENGINE RESULT = ${result.runtimeType}');

      if (result is OperationFailed) {
        debugPrint(result.toString());
      }

      return _FinancialOperationExecution(
        result: result,
        status: result is OperationSucceeded ? 'succeeded' : 'failed',
        operationId: plan.operationId,
        transactionIds: _transactionIds(plan.mutations),
        mutationIds: _mutationIds(plan.mutations),
        error: result is OperationFailed ? result.error.toString() : null,
      );
    } catch (error, stackTrace) {
      debugPrint('POLICY/EXECUTION EXCEPTION:');
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());

      return _FinancialOperationExecution(
        result: OperationFailed(error: error.toString()),
        status: 'failed',
        error: error.toString(),
      );
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
          traceId:
              'trace-${context.idempotencyKey}-${startedAt.microsecondsSinceEpoch}',
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

/// Captures the operation result and trace data produced by the single action.
/// It is kept outside OperationResult so the Guard persists only public results.
final class _FinancialOperationExecution {
  final OperationResult result;
  final String status;
  final String? operationId;
  final List<String> transactionIds;
  final List<String> mutationIds;
  final String? error;

  const _FinancialOperationExecution({
    required this.result,
    required this.status,
    this.operationId,
    this.transactionIds = const <String>[],
    this.mutationIds = const <String>[],
    this.error,
  });
}

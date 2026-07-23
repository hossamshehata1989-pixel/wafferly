import 'package:flutter/foundation.dart';

import '../domain_guard/domain_guard_pipeline.dart';
import '../execution/financial_executor.dart';
import '../execution_context/execution_context.dart';
import '../idempotency/idempotency_guard.dart';
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

  const FinancialOperationEngine({
    required FinancialInterpreter interpreter,
    required DomainGuardPipeline domainGuardPipeline,
    required FinancialPlanner planner,
    required FinancialIntegrityChecker integrityChecker,
    required FinancialExecutor executor,
    required IdempotencyGuard idempotencyGuard,
    PolicyPipeline policyPipeline = const PolicyPipeline(),
  }) : _interpreter = interpreter,
       _domainGuardPipeline = domainGuardPipeline,
       _policyPipeline = policyPipeline,
       _planner = planner,
       _integrityChecker = integrityChecker,
       _executor = executor,
       _idempotencyGuard = idempotencyGuard;

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
      return DomainViolationResult(reason: domainResult.violation!.reason);
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
        return OperationRejected(reason: policyResult.reason);
      }

      if (policyResult is PolicyRequiresConfirmation) {
        return ConfirmationRequired(options: policyResult.options);
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


      return result;
    } catch (e, s) {
      debugPrint('POLICY EXCEPTION:');
      debugPrint(e.toString());
      debugPrint(s.toString());

      return OperationFailed(error: e.toString());
    }
  }
}

import '../domain_guard/domain_guard_pipeline.dart';
import '../domain_guard/domain_guard_result.dart';
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
    // Step 0 — Idempotency
    final cached = await _idempotencyGuard.check(context);

    if (cached != null) {
      return cached;
    }

    // Step 1 — Interpretation
    final intent = _interpreter.interpret(operation);

    // Step 2 — Domain Guard
    final domainResult = await _domainGuardPipeline.validate(intent);

    if (domainResult is DomainViolation) {
      return DomainViolationResult(reason: domainResult.reason);
    }

    // Step 3 — Policy
    final policyResult = await _policyPipeline.evaluate(intent);

    if (policyResult is! PolicyPassed) {
      // TODO:
      // Convert PolicyResult into OperationResult.
      throw UnimplementedError();
    }

    // Step 4 — Planning
    final plan = await _planner.build(intent);

    // Step 5 — Integrity
    _integrityChecker.validate(plan);

    // Step 6 — Execution
    // TODO:
    // Execute FinancialExecutionPlan.
    // Persist Journal Entries.
    // Publish Outbox Events.
    // Return OperationSucceeded.

    final result = await _executor.execute(plan);

    if (result is OperationSucceeded) {
      await _idempotencyGuard.remember(context, result);
    }

    return result;
  }
}

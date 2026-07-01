import '../operations/financial_operation.dart';
import '../policies/policy_pipeline.dart';
import '../policies/policy_result.dart';
import '../results/operation_result.dart';
import '../validators/validation_pipeline.dart';
import '../validators/validation_result.dart';

final class FinancialOperationEngine {
  final ValidationPipeline _validationPipeline;
  final PolicyPipeline _policyPipeline;

  const FinancialOperationEngine({
    ValidationPipeline validationPipeline = const ValidationPipeline(),
    PolicyPipeline policyPipeline = const PolicyPipeline(),
  }) : _validationPipeline = validationPipeline,
       _policyPipeline = policyPipeline;

  Future<OperationResult> execute(FinancialOperation operation) async {
    // Step 1 — Validation
    final validation = await _validationPipeline.validate(operation);

    if (validation is ValidationFailureResult) {
      // TODO(ADR):
      // Convert ValidationFailureResult
      // into the appropriate OperationResult.
      throw UnimplementedError();
    }

    // Step 2 — Policy
    final policy = await _policyPipeline.evaluate(operation);

    if (policy is! PolicyPassed) {
      // TODO(ADR):
      // Convert PolicyResult
      // into the appropriate OperationResult.
      throw UnimplementedError();
    }

    // Step 3 — Execution
    // TODO(ADR):
    // Build FinancialExecutionPlan.
    // Execute FinancialMutations.
    // Return OperationSucceeded.
    throw UnimplementedError();
  }
}

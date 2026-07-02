import '../domain_guard/domain_guard_pipeline.dart';
import '../interpretation/financial_interpreter.dart';
import '../operations/financial_operation.dart';
import '../results/operation_result.dart';
import '../policies/policy_pipeline.dart';
import '../policies/policy_result.dart';

final class FinancialOperationEngine {
  final FinancialInterpreter _interpreter;
  final DomainGuardPipeline _domainGuardPipeline;
  final PolicyPipeline _policyPipeline;

  const FinancialOperationEngine({
    required FinancialInterpreter interpreter,
    required DomainGuardPipeline domainGuardPipeline,
    required PolicyPipeline policyPipeline,
  }) : _interpreter = interpreter,
       _domainGuardPipeline = domainGuardPipeline,
       _policyPipeline = policyPipeline;

  Future<OperationResult> execute(FinancialOperation operation) async {
    final intent = _interpreter.interpret(operation);

    final domainResult = await _domainGuardPipeline.validate(intent);

    final policyResult = await _policyPipeline.evaluate(intent);

    // TODO:
    // Convert DomainGuardResult to OperationResult.
    // Convert PolicyResult to OperationResult.
    // Continue to Planner.

    throw UnimplementedError();
  }
}

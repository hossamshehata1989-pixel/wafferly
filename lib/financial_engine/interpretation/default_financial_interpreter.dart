import '../operations/financial_operation.dart';
import 'financial_interpreter.dart';
import 'interpreter_registry.dart';
import 'normalized_intent.dart';

final class DefaultFinancialInterpreter implements FinancialInterpreter {
  final InterpreterRegistry _registry;

  const DefaultFinancialInterpreter({required InterpreterRegistry registry})
    : _registry = registry;

  @override
  NormalizedIntent interpret(FinancialOperation operation) {
    // TODO(ADR):
    // Delegate interpretation to the registered
    // OperationInterpreter for this operation type.
    throw UnimplementedError();
  }
}

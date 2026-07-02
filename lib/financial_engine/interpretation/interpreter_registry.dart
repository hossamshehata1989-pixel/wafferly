import '../operations/financial_operation.dart';
import 'operation_interpreter.dart';

final class InterpreterRegistry {
  final Map<Type, OperationInterpreter> _interpreters;

  const InterpreterRegistry({
    required Map<Type, OperationInterpreter> interpreters,
  }) : _interpreters = interpreters;

  T interpreterFor<T extends FinancialOperation>() {
    final interpreter = _interpreters[T];

    if (interpreter == null) {
      throw StateError('No interpreter registered for $T.');
    }

    return interpreter as T;
  }
}

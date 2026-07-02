import '../operations/financial_operation.dart';
import 'normalized_intent.dart';

abstract interface class OperationInterpreter<T extends FinancialOperation> {
  NormalizedIntent interpret(T operation);
}

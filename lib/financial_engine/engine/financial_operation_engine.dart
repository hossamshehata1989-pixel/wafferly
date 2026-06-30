import '../operations/financial_operation.dart';
import '../results/operation_result.dart';

class FinancialOperationEngine {
  FinancialOperationEngine._();

  static final FinancialOperationEngine instance = FinancialOperationEngine._();

  Future<OperationResult> execute(FinancialOperation operation) {
    throw UnimplementedError();
  }
}

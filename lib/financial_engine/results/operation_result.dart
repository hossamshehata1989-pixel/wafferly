import '../resolution/resolution.dart';
import '../execution/financial_execution_summary.dart';

sealed class OperationResult {
  const OperationResult();
}

class OperationSucceeded extends OperationResult {
  final FinancialExecutionSummary summary;

  const OperationSucceeded({required this.summary});
}

class ValidationFailed extends OperationResult {
  final String reason;

  const ValidationFailed({required this.reason});
}

class InsufficientBalance extends OperationResult {
  final double required;
  final double available;
  final List<Resolution> options;

  const InsufficientBalance({
    required this.required,
    required this.available,
    required this.options,
  });
}

class UserConfirmationRequired extends OperationResult {
  final List<Resolution> options;

  const UserConfirmationRequired({required this.options});
}

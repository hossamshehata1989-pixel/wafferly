import '../execution/financial_execution_summary.dart';
import '../resolution/resolution.dart';

sealed class OperationResult {
  const OperationResult();
}

final class OperationSucceeded extends OperationResult {
  final FinancialExecutionSummary summary;

  const OperationSucceeded({required this.summary});
}

final class ValidationFailed extends OperationResult {
  final String reason;

  const ValidationFailed({required this.reason});
}

final class InsufficientBalance extends OperationResult {
  final double required;
  final double available;
  final List<Resolution> options;

  const InsufficientBalance({
    required this.required,
    required this.available,
    required this.options,
  });
}

final class UserConfirmationRequired extends OperationResult {
  final List<Resolution> options;

  const UserConfirmationRequired({required this.options});
}

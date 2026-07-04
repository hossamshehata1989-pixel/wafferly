import '../execution/financial_execution_summary.dart';
import '../resolution/resolution.dart';

sealed class OperationResult {
  const OperationResult();
}

final class OperationSucceeded extends OperationResult {
  final FinancialExecutionSummary summary;

  const OperationSucceeded({required this.summary});
}

final class OperationFailed extends OperationResult {
  final Object error;

  const OperationFailed({required this.error});
}

final class DomainViolationResult extends OperationResult {
  final String reason;

  const DomainViolationResult({required this.reason});
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

final class OperationRejected extends OperationResult {
  final String reason;

  const OperationRejected({required this.reason});
}

final class ConfirmationRequired extends OperationResult {
  final List<Resolution> options;

  const ConfirmationRequired({required this.options});
}

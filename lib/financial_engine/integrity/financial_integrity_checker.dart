import '../planning/financial_execution_plan.dart';

abstract interface class FinancialIntegrityChecker {
  void validate(FinancialExecutionPlan plan);
}

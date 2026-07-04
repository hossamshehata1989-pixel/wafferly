import '../planning/financial_mutation.dart';

abstract interface class FinancialMutationHandler<T extends FinancialMutation> {
  Future<void> execute(T mutation);
}

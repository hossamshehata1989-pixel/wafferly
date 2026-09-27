import '../../models/financing/statement_installment_contribution.dart';

/// Persistence boundary for statement/installment relationship state.
///
/// This repository owns only the derived statement contribution/read-model.
/// It must never mutate Account, Transaction, Ledger, Balance, or Financial
/// Engine state.
abstract interface class StatementInstallmentContributionRepository {
  StatementInstallmentContribution? get(String contributionId);

  Iterable<StatementInstallmentContribution> get values;

  Iterable<StatementInstallmentContribution> findByStatementId(
    String statementId,
  );

  Iterable<StatementInstallmentContribution> findByInstallmentId(
    String installmentId,
  );

  Future<void> put(StatementInstallmentContribution contribution);
}

import 'package:hive/hive.dart';

import '../../models/financing/statement_installment_contribution.dart';
import '../domain/statement_installment_contribution_repository.dart';

final class HiveStatementInstallmentContributionRepository
    implements StatementInstallmentContributionRepository {
  final Box<StatementInstallmentContribution> _box;

  const HiveStatementInstallmentContributionRepository(this._box);

  @override
  StatementInstallmentContribution? get(String contributionId) {
    return _box.get(contributionId);
  }

  @override
  Iterable<StatementInstallmentContribution> get values => _box.values;

  @override
  Iterable<StatementInstallmentContribution> findByStatementId(
    String statementId,
  ) {
    return _box.values.where((item) => item.statementId == statementId);
  }

  @override
  Iterable<StatementInstallmentContribution> findByInstallmentId(
    String installmentId,
  ) {
    return _box.values.where((item) => item.installmentId == installmentId);
  }

  @override
  Future<void> put(StatementInstallmentContribution contribution) async {
    final existing = _box.get(contribution.contributionId);
    if (existing != null) {
      if (!_sameValue(existing, contribution)) {
        throw StateError(
          'Statement contribution identity is already bound to different data.',
        );
      }
      return;
    }

    await _box.put(contribution.contributionId, contribution);
  }

  bool _sameValue(
    StatementInstallmentContribution left,
    StatementInstallmentContribution right,
  ) {
    return left.contributionId == right.contributionId &&
        left.statementId == right.statementId &&
        left.contractId == right.contractId &&
        left.installmentId == right.installmentId &&
        left.principalValue == right.principalValue &&
        left.interestValue == right.interestValue &&
        left.feesValue == right.feesValue &&
        left.contributionValue == right.contributionValue;
  }
}

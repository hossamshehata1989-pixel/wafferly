import 'package:hive/hive.dart';

import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/financing/statement_installment_contribution.dart';
import 'statement_installment_contribution_repository.dart';

/// Materializes installment contributions for one already-defined statement
/// cycle.
///
/// Statement identity and cycle boundaries belong to the statement domain.
/// This service only owns the Statement ↔ Installment read-model boundary.
/// It does not create statements, calculate interest, or mutate financial
/// truth.
final class CreditCardStatementInstallmentService {
  final Box<FinancingContract> _contracts;
  final Box<FinancingInstallment> _installments;
  final StatementInstallmentContributionRepository _contributions;

  const CreditCardStatementInstallmentService({
    required Box<FinancingContract> contracts,
    required Box<FinancingInstallment> installments,
    required StatementInstallmentContributionRepository contributions,
  })  : _contracts = contracts,
        _installments = installments,
        _contributions = contributions;

  /// Creates the deterministic contribution rows for installments whose due
  /// date is in [cycleStartInclusive, cycleEndExclusive).
  ///
  /// A repeated invocation with the same statement/period is idempotent.
  /// Existing contribution identity may not be rebound to different values.
  Future<List<StatementInstallmentContribution>> generateForCycle({
    required String statementId,
    required String liabilityAccountId,
    required DateTime cycleStartInclusive,
    required DateTime cycleEndExclusive,
    required DateTime createdAt,
  }) async {
    _validateInputs(
      statementId: statementId,
      liabilityAccountId: liabilityAccountId,
      cycleStartInclusive: cycleStartInclusive,
      cycleEndExclusive: cycleEndExclusive,
      createdAt: createdAt,
    );

    final eligible = <FinancingInstallment>[];

    for (final installment in _installments.values) {
      if (installment.dueDate.isBefore(cycleStartInclusive) ||
          !installment.dueDate.isBefore(cycleEndExclusive)) {
        continue;
      }

      final contract = _contracts.get(installment.contractId);
      if (contract == null ||
          contract.liabilityAccountId != liabilityAccountId) {
        continue;
      }

      eligible.add(installment);
    }

    eligible.sort((a, b) {
      final byDate = a.dueDate.compareTo(b.dueDate);
      if (byDate != 0) return byDate;
      return a.installmentId.compareTo(b.installmentId);
    });

    final contributions = <StatementInstallmentContribution>[];
    for (final installment in eligible) {
      final contribution = StatementInstallmentContribution(
        contributionId: StatementInstallmentContribution.idFor(
          statementId: statementId,
          installmentId: installment.installmentId,
        ),
        statementId: statementId,
        contractId: installment.contractId,
        installmentId: installment.installmentId,
        principalValue: installment.principalComponent.toString(),
        interestValue: installment.interestComponent.toString(),
        feesValue: installment.fees.toString(),
        contributionValue: installment.amount.toString(),
        createdAt: createdAt,
      );

      await _contributions.put(contribution);
      contributions.add(_contributions.get(contribution.contributionId)!);
    }

    return contributions;
  }

  void _validateInputs({
    required String statementId,
    required String liabilityAccountId,
    required DateTime cycleStartInclusive,
    required DateTime cycleEndExclusive,
    required DateTime createdAt,
  }) {
    if (statementId.trim().isEmpty) {
      throw ArgumentError('Statement identity must not be empty.');
    }
    if (liabilityAccountId.trim().isEmpty) {
      throw ArgumentError('Liability account identity must not be empty.');
    }
    if (!cycleStartInclusive.isBefore(cycleEndExclusive)) {
      throw ArgumentError(
        'Statement cycle start must be before cycle end.',
      );
    }
  }
}

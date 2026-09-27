import '../../core/money/money.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_conversion_event.dart';
import '../../models/financing/statement_installment_contribution.dart';
import '../../constants/transaction_constants.dart';
import '../../models/transaction.dart';

/// A statement-period line produced by the financing-aware projection.
///
/// This is a read model only. It must never be used as a source for Account,
/// Transaction, Ledger, or Balance mutation.
final class CreditCardStatementProjectionLine {
  final String lineId;
  final Money amount;
  final String kind;
  final String? originChargeId;
  final String? installmentId;

  const CreditCardStatementProjectionLine({
    required this.lineId,
    required this.amount,
    required this.kind,
    this.originChargeId,
    this.installmentId,
  });
}

/// Projects a credit-card statement without representing a converted charge
/// twice.
///
/// The key boundary is the statement closing date:
/// - conversion effective on/before close replaces the full originating charge
///   with eligible installment contributions;
/// - conversion effective after close leaves the historical charge intact.
///
/// No persistence or financial mutation occurs here.
final class CreditCardStatementProjection {
  final Iterable<Transaction> transactions;
  final Iterable<FinancingConversionEvent> conversionEvents;
  final Iterable<FinancingContract> contracts;
  final Iterable<StatementInstallmentContribution> contributions;

  const CreditCardStatementProjection({
    required this.transactions,
    required this.conversionEvents,
    required this.contracts,
    required this.contributions,
  });

  List<CreditCardStatementProjectionLine> project({
    required String statementId,
    required String liabilityAccountId,
    required DateTime cycleStartInclusive,
    required DateTime cycleEndExclusive,
  }) {
    if (statementId.trim().isEmpty) {
      throw ArgumentError('Statement identity must not be empty.');
    }
    if (!cycleStartInclusive.isBefore(cycleEndExclusive)) {
      throw ArgumentError('Statement cycle start must be before cycle end.');
    }

    final contractById = <String, FinancingContract>{
      for (final contract in contracts) contract.contractId: contract,
    };
    final completedConversionByCharge = <String, FinancingConversionEvent>{};

    for (final event in conversionEvents) {
      if (event.status != 'completed') continue;
      completedConversionByCharge[event.originChargeId] = event;
    }

    final result = <CreditCardStatementProjectionLine>[];

    // First project the original posted charges. A converted charge is either
    // retained as historical statement truth when its conversion became
    // effective after this statement closed, or suppressed here so that its
    // statement representation can come exclusively from ADR-069
    // installment contributions below.
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.creditCardCharge ||
          transaction.toAccountId != liabilityAccountId) {
        continue;
      }

      if (transaction.date.isBefore(cycleStartInclusive) ||
          !transaction.date.isBefore(cycleEndExclusive)) {
        continue;
      }

      final conversion = completedConversionByCharge[transaction.id];
      if (conversion == null) {
        result.add(
          CreditCardStatementProjectionLine(
            lineId: 'charge:${transaction.id}',
            amount: Money.fromDouble(transaction.amount),
            kind: 'originating_charge',
            originChargeId: transaction.id,
          ),
        );
        continue;
      }

      final contract = contractById[conversion.contractId];
      if (contract == null || contract.liabilityAccountId != liabilityAccountId) {
        throw StateError(
          'Completed financing conversion is missing its matching contract.',
        );
      }

      // Conversion effective after this statement closed cannot rewrite the
      // historical statement. Keep the original posted charge there.
      if (_conversionOccursAfterStatementClose(
        contract.effectiveDate,
        cycleEndExclusive,
      )) {
        result.add(
          CreditCardStatementProjectionLine(
            lineId: 'charge:${transaction.id}',
            amount: Money.fromDouble(transaction.amount),
            kind: 'originating_charge',
            originChargeId: transaction.id,
          ),
        );
      }
    }

    // StatementInstallmentContribution is already scoped to a concrete
    // statement identity by ADR-069. Project it independently from the
    // originating transaction loop: the original charge is deliberately not
    // the carrier of installment presentation state.
    for (final contribution in contributions) {
      if (contribution.statementId != statementId) continue;

      final contract = contractById[contribution.contractId];
      if (contract == null || contract.liabilityAccountId != liabilityAccountId) {
        continue;
      }

      result.add(
        CreditCardStatementProjectionLine(
          lineId: 'installment:${contribution.contributionId}',
          amount: contribution.contribution,
          kind: 'installment_contribution',
          originChargeId: contract.originReference,
          installmentId: contribution.installmentId,
        ),
      );
    }

    result.sort((a, b) => a.lineId.compareTo(b.lineId));
    return List.unmodifiable(result);
  }

  bool _conversionOccursAfterStatementClose(
    DateTime conversionEffectiveDate,
    DateTime statementCloseExclusive,
  ) {
    // Statement boundaries are calendar boundaries. Compare the instant in a
    // common timezone so a persisted local/UTC DateTime cannot accidentally
    // change the historical-vs-future classification. A conversion strictly
    // after the close cannot rewrite the already-closed period.
    return conversionEffectiveDate.toUtc().isAfter(
      statementCloseExclusive.toUtc(),
    );
  }

  Money totalFor({
    required String statementId,
    required String liabilityAccountId,
    required DateTime cycleStartInclusive,
    required DateTime cycleEndExclusive,
  }) {
    return project(
      statementId: statementId,
      liabilityAccountId: liabilityAccountId,
      cycleStartInclusive: cycleStartInclusive,
      cycleEndExclusive: cycleEndExclusive,
    ).fold(Money.zero, (sum, line) => sum + line.amount);
  }
}

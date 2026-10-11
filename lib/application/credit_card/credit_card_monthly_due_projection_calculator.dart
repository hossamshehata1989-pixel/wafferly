import '../../constants/transaction_constants.dart';
import '../../core/money/money.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/transaction.dart';
import 'credit_card_expense_projection_service.dart';

/// Projects current- and next-month card obligations. Missing statement-cycle
/// settings fall back to calendar-month due dates. This is read-side only and
/// never mutates installment status or financial transactions.
final class CreditCardMonthlyDueBreakdown {
  const CreditCardMonthlyDueBreakdown({
    required this.thisMonthExpenses,
    required this.thisMonthInstallments,
    required this.nextMonthExpenses,
    required this.nextMonthInstallments,
  });

  final Money thisMonthExpenses;
  final Money thisMonthInstallments;
  final Money nextMonthExpenses;
  final Money nextMonthInstallments;

  Money get thisMonthTotal => thisMonthExpenses + thisMonthInstallments;
  Money get nextMonthTotal => nextMonthExpenses + nextMonthInstallments;
}

final class CreditCardMonthlyDueProjectionCalculator {
  const CreditCardMonthlyDueProjectionCalculator();

  CreditCardMonthlyDueBreakdown calculate({
    required String liabilityAccountId,
    required Iterable<Transaction> charges,
    required Iterable<Transaction> payments,
    required Iterable<FinancingContract> contracts,
    required Iterable<FinancingInstallment> installments,
    required int? statementDay,
    required int? paymentDueDay,
    required Money currentOutstanding,
    required DateTime now,
  }) {
    final today = _dateOnly(now);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    final nextMonthEnd = DateTime(now.year, now.month + 2, 0);

    final cardContracts = contracts.where((contract) {
      final state = contract.lifecycleState.trim().toLowerCase();
      return contract.liabilityAccountId == liabilityAccountId &&
          state != 'cancelled' &&
          state != 'canceled';
    }).toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    final contractByOrigin = <String, FinancingContract>{};
    final contractById = <String, FinancingContract>{};
    for (final contract in cardContracts) {
      contractByOrigin[contract.originReference] = contract;
      contractById[contract.contractId] = contract;
    }

    final lines = <_DueLine>[];
    for (final charge in charges) {
      if (charge.type != TransactionType.creditCardCharge ||
          charge.toAccountId != liabilityAccountId ||
          _dateOnly(charge.date).isAfter(today)) {
        continue;
      }

      final closeDate =
          CreditCardExpenseProjectionService.statementCloseDateForCharge(
        charge.date,
        statementDay,
      );
      final conversion = contractByOrigin[charge.id];
      // A conversion made before/on cycle close replaces the full purchase by
      // its installment schedule. A later conversion cannot rewrite a closed
      // statement, so the original charge remains a due obligation.
      if (conversion != null &&
          !_dateOnly(conversion.effectiveDate).isAfter(closeDate)) {
        continue;
      }

      lines.add(
        _DueLine(
          id: 'charge:${charge.id}',
          eventDate: charge.date,
          dueDate: CreditCardExpenseProjectionService.expenseDateForCharge(
            charge.date,
            statementDay,
            paymentDueDay,
          ),
          remaining: Money.fromDouble(charge.amount).abs(),
          isInstallment: false,
        ),
      );
    }

    for (final installment in installments) {
      final contract = contractById[installment.contractId];
      final contractState = contract?.lifecycleState.trim().toLowerCase();
      final status = installment.status.trim().toLowerCase();
      if (contract == null ||
          contractState == 'terminated' ||
          status == 'cancelled' ||
          status == 'canceled' ||
          status == 'settled' ||
          status == 'superseded' ||
          status == 'terminated') {
        continue;
      }

      // Unlike a purchase charge, an installment already has a contractual
      // due date. Do not run it through the card's statement-cycle mapper a
      // second time: doing so shifts installments that fall on/after the close
      // day into a later billing cycle (for example Nov 15 -> Jan 15 when the
      // statement closes on the 14th and payment is due on the 15th).
      final installmentDueDate = _dateOnly(installment.dueDate);
      lines.add(
        _DueLine(
          id: 'installment:${installment.installmentId}',
          eventDate: installmentDueDate,
          dueDate: installmentDueDate,
          remaining: installment.amount,
          isInstallment: true,
        ),
      );
    }

    final orderedPayments = payments
        .where((payment) =>
            payment.type == TransactionType.transfer &&
            payment.source == TransactionSource.creditCardPayment &&
            payment.toAccountId == liabilityAccountId &&
            !_dateOnly(payment.date).isAfter(today))
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    for (final payment in orderedPayments) {
      var unapplied = Money.fromDouble(payment.amount).abs();
      if (unapplied <= Money.zero) continue;

      final eligible = lines
          .where((line) =>
              line.remaining > Money.zero &&
              !_dateOnly(line.eventDate).isAfter(_dateOnly(payment.date)))
          .toList()
        ..sort(_compareLines);

      for (final line in eligible) {
        if (unapplied <= Money.zero) break;
        final applied = line.remaining < unapplied ? line.remaining : unapplied;
        line.remaining -= applied;
        unapplied -= applied;
      }

      // Any excess is a prepayment for the earliest future installment, not a
      // second liability credit and not an early-settlement of the contract.
      if (unapplied > Money.zero) {
        final futureInstallments = lines
            .where((line) =>
                line.isInstallment &&
                _dateOnly(line.eventDate).isAfter(_dateOnly(payment.date)) &&
                line.remaining > Money.zero)
            .toList()
          ..sort(_compareLines);

        for (final line in futureInstallments) {
          if (unapplied <= Money.zero) break;
          final applied = line.remaining < unapplied ? line.remaining : unapplied;
          line.remaining -= applied;
          unapplied -= applied;
        }
      }
    }

    // Keep the two displayed month totals consistent with the authoritative
    // liability balance. Oldest due lines consume the cap first.
    lines.sort(_compareLines);
    var remainingCap = currentOutstanding;
    var thisExpenses = Money.zero;
    var thisInstallments = Money.zero;
    var nextExpenses = Money.zero;
    var nextInstallments = Money.zero;

    for (final line in lines) {
      if (remainingCap <= Money.zero) break;
      if (line.remaining <= Money.zero ||
          _dateOnly(line.dueDate).isAfter(_dateOnly(nextMonthEnd))) {
        continue;
      }

      final counted = line.remaining < remainingCap ? line.remaining : remainingCap;
      remainingCap -= counted;
      if (!_dateOnly(line.dueDate).isAfter(_dateOnly(currentMonthEnd))) {
        if (line.isInstallment) {
          thisInstallments += counted;
        } else {
          thisExpenses += counted;
        }
      } else if (line.isInstallment) {
        nextInstallments += counted;
      } else {
        nextExpenses += counted;
      }
    }

    return CreditCardMonthlyDueBreakdown(
      thisMonthExpenses: thisExpenses,
      thisMonthInstallments: thisInstallments,
      nextMonthExpenses: nextExpenses,
      nextMonthInstallments: nextInstallments,
    );
  }

  static int _compareLines(_DueLine a, _DueLine b) {
    final byDue = a.dueDate.compareTo(b.dueDate);
    if (byDue != 0) return byDue;
    final byEvent = a.eventDate.compareTo(b.eventDate);
    return byEvent != 0 ? byEvent : a.id.compareTo(b.id);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

final class _DueLine {
  _DueLine({
    required this.id,
    required this.eventDate,
    required this.dueDate,
    required this.remaining,
    required this.isInstallment,
  });

  final String id;
  final DateTime eventDate;
  final DateTime dueDate;
  Money remaining;
  final bool isInstallment;
}

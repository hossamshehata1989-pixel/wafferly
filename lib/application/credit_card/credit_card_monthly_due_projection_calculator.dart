import '../../constants/transaction_constants.dart';
import '../../core/money/money.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/transaction.dart';
import 'credit_card_due_date_policy.dart';
import 'credit_card_expense_projection_service.dart';

/// One month's projected credit-card dues, split by purchase expenses and
/// contractual installments.
final class CreditCardMonthDueProjection {
  const CreditCardMonthDueProjection({
    required this.monthStart,
    required this.expenses,
    required this.installments,
  });

  final DateTime monthStart;
  final Money expenses;
  final Money installments;

  Money get total => expenses + installments;
}

/// Read-side projection across a rolling window of months.
final class CreditCardMonthlyDueBreakdown {
  const CreditCardMonthlyDueBreakdown({
    required this.thisMonthExpenses,
    required this.thisMonthInstallments,
    required this.nextMonthExpenses,
    required this.nextMonthInstallments,
    this.months = const <CreditCardMonthDueProjection>[],
  });

  final Money thisMonthExpenses;
  final Money thisMonthInstallments;
  final Money nextMonthExpenses;
  final Money nextMonthInstallments;
  final List<CreditCardMonthDueProjection> months;

  Money get thisMonthTotal => thisMonthExpenses + thisMonthInstallments;
  Money get nextMonthTotal => nextMonthExpenses + nextMonthInstallments;
}

/// Projects credit-card obligations by due month. It never mutates statement,
/// transaction or installment records.
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
    String dueDateCalculationMethod = CreditCardDueDatePolicy.fixedCalendarDay,
    int? dueDaysAfterStatement,
    String weekendHolidayPolicy = CreditCardDueDatePolicy.noAdjustment,
    int monthsToProject = 12,
  }) {
    final today = _dateOnly(now);
    final monthCount = monthsToProject.clamp(2, 24).toInt();
    final firstMonth = DateTime(now.year, now.month, 1);
    final lastMonthEnd = DateTime(now.year, now.month + monthCount, 0);

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

      final closeDate = CreditCardExpenseProjectionService.statementCloseDateForCharge(
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

      final dueDate = CreditCardExpenseProjectionService.expenseDateForCharge(
        charge.date,
        statementDay,
        paymentDueDay,
        dueDateCalculationMethod: dueDateCalculationMethod,
        dueDaysAfterStatement: dueDaysAfterStatement,
        weekendHolidayPolicy: weekendHolidayPolicy,
      );

      lines.add(
        _DueLine(
          id: 'charge:${charge.id}',
          eventDate: charge.date,
          dueDate: dueDate,
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

      // Contractual installment due dates are already authoritative schedule
      // dates. Do not map them through the statement cycle again.
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
        line.remaining = line.remaining - applied;
        unapplied = unapplied - applied;
      }

      // An excess payment is applied to the earliest future installment.
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
          line.remaining = line.remaining - applied;
          unapplied = unapplied - applied;
        }
      }
    }

    // Reconcile all projected obligations to the current liability balance,
    // oldest due month first. This avoids a future projection exceeding what
    // the ledger says is still outstanding.
    lines.sort(_compareLines);
    var remainingCap = currentOutstanding;
    final expenseByMonth = <int, Money>{};
    final installmentByMonth = <int, Money>{};
    for (final line in lines) {
      if (remainingCap <= Money.zero) break;
      if (line.remaining <= Money.zero ||
          _dateOnly(line.dueDate).isAfter(_dateOnly(lastMonthEnd))) {
        continue;
      }

      final counted = line.remaining < remainingCap ? line.remaining : remainingCap;
      remainingCap = remainingCap - counted;
      final dueDate = _dateOnly(line.dueDate);
      final key = dueDate.isBefore(firstMonth)
          ? _monthKey(firstMonth)
          : _monthKey(dueDate);
      if (line.isInstallment) {
        installmentByMonth[key] = (installmentByMonth[key] ?? Money.zero) + counted;
      } else {
        expenseByMonth[key] = (expenseByMonth[key] ?? Money.zero) + counted;
      }
    }

    final months = <CreditCardMonthDueProjection>[];
    for (var index = 0; index < monthCount; index++) {
      final monthStart = DateTime(firstMonth.year, firstMonth.month + index, 1);
      final key = _monthKey(monthStart);
      months.add(
        CreditCardMonthDueProjection(
          monthStart: monthStart,
          expenses: expenseByMonth[key] ?? Money.zero,
          installments: installmentByMonth[key] ?? Money.zero,
        ),
      );
    }

    final current = months.isNotEmpty ? months[0] : null;
    final next = months.length > 1 ? months[1] : null;
    return CreditCardMonthlyDueBreakdown(
      thisMonthExpenses: current?.expenses ?? Money.zero,
      thisMonthInstallments: current?.installments ?? Money.zero,
      nextMonthExpenses: next?.expenses ?? Money.zero,
      nextMonthInstallments: next?.installments ?? Money.zero,
      months: List.unmodifiable(months),
    );
  }

  static int _compareLines(_DueLine a, _DueLine b) {
    final byDue = a.dueDate.compareTo(b.dueDate);
    if (byDue != 0) return byDue;
    final byEvent = a.eventDate.compareTo(b.eventDate);
    return byEvent != 0 ? byEvent : a.id.compareTo(b.id);
  }

  static int _monthKey(DateTime date) => date.year * 100 + date.month;

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

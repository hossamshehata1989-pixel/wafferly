import '../../constants/transaction_constants.dart';
import '../../core/money/money.dart';
import '../../credit_card/domain/credit_card_profile.dart';
import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import '../../models/transaction.dart';

/// Read-side estimate of the unpaid statement amount whose payment due date
/// falls in the current calendar month.
///
/// This is derived from Wafferly's effective transaction history. It is not an
/// imported/persisted bank statement; importing and closing official statements
/// remain separate lifecycle work (ADR-050).
final class CreditCardStatementDueSummary {
  const CreditCardStatementDueSummary({
    required this.amountDue,
    required this.chargeAmountDue,
    required this.installmentAmountDue,
    required this.statementCloseDate,
    required this.paymentDueDate,
  });

  final Money amountDue;
  final Money chargeAmountDue;
  final Money installmentAmountDue;
  final DateTime? statementCloseDate;
  final DateTime? paymentDueDate;

  bool get isConfigured =>
      statementCloseDate != null && paymentDueDate != null;
}

/// Calculates the current payable statement amount from recorded card activity.
///
/// Payments are allocated to the oldest eligible statement obligation first.
/// Converted purchase charges are omitted from a cycle when the financing
/// conversion was effective before that cycle closed; the scheduled
/// installments are then included in their respective statement cycles.
final class CreditCardStatementDueCalculator {
  const CreditCardStatementDueCalculator();

  CreditCardStatementDueSummary calculate({
    required String liabilityAccountId,
    required CreditCardProfile profile,
    required Money currentOutstanding,
    required Iterable<Transaction> charges,
    required Iterable<Transaction> payments,
    required Iterable<FinancingInstallment> installments,
    required Iterable<FinancingContract> contracts,
    required DateTime now,
  }) {
    final closingDay = profile.statementDay;
    final dueDay = profile.paymentDueDay;
    if (closingDay == null || dueDay == null) {
      return CreditCardStatementDueSummary(
        amountDue: Money.zero,
        chargeAmountDue: Money.zero,
        installmentAmountDue: Money.zero,
        statementCloseDate: null,
        paymentDueDate: null,
      );
    }

    _validateDay(closingDay, 'statementDay');
    _validateDay(dueDay, 'paymentDueDay');

    final previousMonth = _monthStart(now.year, now.month - 1);
    final statementCloseDate = _dateForDay(
      previousMonth.year,
      previousMonth.month,
      closingDay,
    );
    final paymentDueDate = _dateForDay(now.year, now.month, dueDay);

    final activeContracts = contracts.where((contract) {
      final state = contract.lifecycleState.trim().toLowerCase();
      return contract.liabilityAccountId == liabilityAccountId &&
          state != 'cancelled' &&
          state != 'terminated';
    }).toList(growable: false);
    final contractById = <String, FinancingContract>{
      for (final contract in activeContracts) contract.contractId: contract,
    };
    final contractByOrigin = <String, FinancingContract>{
      for (final contract in activeContracts) contract.originReference: contract,
    };

    final lines = <_StatementObligation>[];

    for (final charge in charges) {
      if (charge.type != TransactionType.creditCardCharge ||
          charge.toAccountId != liabilityAccountId ||
          _calendarDateAfter(charge.date, now)) {
        continue;
      }

      final closeDate = _closingDateForEvent(charge.date, closingDay);
      final conversion = contractByOrigin[charge.id];
      // A conversion effective after this cycle's close cannot rewrite the
      // historical statement; an earlier/equal conversion suppresses the
      // original charge so that scheduled installments represent it instead.
      if (conversion != null &&
          !_calendarDateAfter(conversion.effectiveDate, closeDate)) {
        continue;
      }

      lines.add(
        _StatementObligation(
          id: 'charge:${charge.id}',
          eventDate: charge.date,
          dueDate: _paymentDueDateForClose(closeDate, dueDay),
          remaining: Money.fromDouble(charge.amount).abs(),
          isInstallment: false,
        ),
      );
    }

    for (final installment in installments) {
      final contract = contractById[installment.contractId];
      final status = installment.status.trim().toLowerCase();
      if (contract == null ||
          status == 'cancelled' ||
          status == 'canceled' ||
          status == 'superseded' ||
          status == 'settled' ||
          status == 'terminated' ||
          _calendarDateAfter(installment.dueDate, now)) {
        continue;
      }

      final closeDate = _closingDateForEvent(installment.dueDate, closingDay);
      lines.add(
        _StatementObligation(
          id: 'installment:${installment.installmentId}',
          eventDate: installment.dueDate,
          dueDate: _paymentDueDateForClose(closeDate, dueDay),
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
            !payment.date.isAfter(now))
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
              !line.remaining.isZero &&
              !line.eventDate.isAfter(payment.date))
          .toList()
        ..sort((a, b) {
          final byDue = a.dueDate.compareTo(b.dueDate);
          if (byDue != 0) return byDue;
          final byEvent = a.eventDate.compareTo(b.eventDate);
          return byEvent != 0 ? byEvent : a.id.compareTo(b.id);
        });

      for (final line in eligible) {
        if (unapplied <= Money.zero) break;
        final applied = line.remaining < unapplied ? line.remaining : unapplied;
        line.remaining = line.remaining - applied;
        unapplied = unapplied - applied;
      }
    }

    // Include this month's statement amount and any prior unpaid obligations
    // carried forward to its due date. If transaction history and the current
    // authoritative balance disagree, cap oldest due obligations first so the
    // shown category subtotals still reconcile to the amount offered for payment.
    final payableLines = lines
        .where((line) => !line.dueDate.isAfter(paymentDueDate))
        .toList()
      ..sort((a, b) {
        final byDue = a.dueDate.compareTo(b.dueDate);
        if (byDue != 0) return byDue;
        final byEvent = a.eventDate.compareTo(b.eventDate);
        return byEvent != 0 ? byEvent : a.id.compareTo(b.id);
      });

    var remainingCap = currentOutstanding;
    var due = Money.zero;
    var chargeDue = Money.zero;
    var installmentDue = Money.zero;
    for (final line in payableLines) {
      if (remainingCap <= Money.zero) break;
      if (line.remaining <= Money.zero) continue;
      final counted = line.remaining < remainingCap ? line.remaining : remainingCap;
      due = due + counted;
      if (line.isInstallment) {
        installmentDue = installmentDue + counted;
      } else {
        chargeDue = chargeDue + counted;
      }
      remainingCap = remainingCap - counted;
    }

    return CreditCardStatementDueSummary(
      amountDue: due,
      chargeAmountDue: chargeDue,
      installmentAmountDue: installmentDue,
      statementCloseDate: statementCloseDate,
      paymentDueDate: paymentDueDate,
    );
  }

  static DateTime _closingDateForEvent(DateTime eventDate, int requestedDay) {
    final closeThisMonth = _dateForDay(
      eventDate.year,
      eventDate.month,
      requestedDay,
    );
    if (eventDate.day <= closeThisMonth.day) return closeThisMonth;

    final nextMonth = _monthStart(eventDate.year, eventDate.month + 1);
    return _dateForDay(nextMonth.year, nextMonth.month, requestedDay);
  }

  static DateTime _paymentDueDateForClose(DateTime closeDate, int dueDay) {
    final nextMonth = _monthStart(closeDate.year, closeDate.month + 1);
    return _dateForDay(nextMonth.year, nextMonth.month, dueDay);
  }

  static DateTime _monthStart(int year, int month) {
    var normalizedYear = year;
    var normalizedMonth = month;
    while (normalizedMonth < 1) {
      normalizedMonth += 12;
      normalizedYear -= 1;
    }
    while (normalizedMonth > 12) {
      normalizedMonth -= 12;
      normalizedYear += 1;
    }
    return DateTime(normalizedYear, normalizedMonth, 1);
  }

  static DateTime _dayAfter(DateTime date) {
    final lastDay = _daysInMonth(date.year, date.month);
    if (date.day < lastDay) {
      return DateTime(date.year, date.month, date.day + 1);
    }
    final nextMonth = _monthStart(date.year, date.month + 1);
    return DateTime(nextMonth.year, nextMonth.month, 1);
  }

  static DateTime _dateForDay(int year, int month, int requestedDay) {
    final normalizedMonthStart = _monthStart(year, month);
    final normalizedYear = normalizedMonthStart.year;
    final normalizedMonth = normalizedMonthStart.month;
    final lastDay = _daysInMonth(normalizedYear, normalizedMonth);
    final day = requestedDay.clamp(1, lastDay).toInt();
    return DateTime(normalizedYear, normalizedMonth, day);
  }

  static int _daysInMonth(int year, int month) {
    const days = <int>[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month != 2) return days[month - 1];
    final isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    return isLeapYear ? 29 : 28;
  }

  static bool _calendarDateAfter(DateTime first, DateTime second) {
    final firstDate = DateTime(first.year, first.month, first.day);
    final secondDate = DateTime(second.year, second.month, second.day);
    return firstDate.isAfter(secondDate);
  }

  static void _validateDay(int day, String field) {
    if (day < 1 || day > 31) {
      throw ArgumentError.value(day, field, 'Must be between 1 and 31.');
    }
  }
}

final class _StatementObligation {
  _StatementObligation({
    required this.id,
    required this.eventDate,
    required this.dueDate,
    required this.remaining,
    required this.isInstallment,
  });

  final String id;
  final DateTime eventDate;
  final DateTime dueDate;
  final bool isInstallment;
  Money remaining;
}

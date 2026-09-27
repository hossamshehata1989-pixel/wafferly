import '../../core/money/money.dart';
import '../../models/financing/financing_installment.dart';

/// Pure input snapshot for allocating a payment against one financing
/// installment. It intentionally carries outstanding components rather than
/// mutating the persisted installment.
class FinancingInstallmentPaymentTarget {
  final FinancingInstallment installment;
  final Money outstandingFees;
  final Money outstandingInterest;
  final Money outstandingPrincipal;

  const FinancingInstallmentPaymentTarget({
    required this.installment,
    required this.outstandingFees,
    required this.outstandingInterest,
    required this.outstandingPrincipal,
  });

  Money get outstandingTotal =>
      outstandingFees + outstandingInterest + outstandingPrincipal;
}

/// Pure result for one installment allocation.
class FinancingInstallmentPaymentAllocation {
  final String installmentId;
  final Money fees;
  final Money interest;
  final Money principal;
  final Money allocatedAmount;
  final Money unallocatedAmount;

  const FinancingInstallmentPaymentAllocation({
    required this.installmentId,
    required this.fees,
    required this.interest,
    required this.principal,
    required this.allocatedAmount,
    required this.unallocatedAmount,
  });
}

/// Pure result for a multi-installment payment allocation.
class FinancingPaymentAllocationResult {
  final List<FinancingInstallmentPaymentAllocation> allocations;
  final Money allocatedAmount;
  final Money unallocatedAmount;

  const FinancingPaymentAllocationResult({
    required this.allocations,
    required this.allocatedAmount,
    required this.unallocatedAmount,
  });

  bool get isFullyAllocated => unallocatedAmount.isZero;
}

/// Pure payment allocation calculator implementing ADR-054/ADR-055.
///
/// Allocation order is Fees -> Interest -> Principal. Installments are
/// ordered by overdue, due today, then future; within each group the earliest
/// due date wins, with installmentId as the deterministic tie-breaker.
class FinancingPaymentAllocationCalculator {
  const FinancingPaymentAllocationCalculator();

  FinancingInstallmentPaymentAllocation allocateToInstallment({
    required Money payment,
    required FinancingInstallmentPaymentTarget target,
  }) {
    _validatePayment(payment);
    _validateTarget(target);

    var remaining = payment;
    final fees = _take(remaining, target.outstandingFees);
    remaining = remaining - fees;

    final interest = _take(remaining, target.outstandingInterest);
    remaining = remaining - interest;

    final principal = _take(remaining, target.outstandingPrincipal);
    remaining = remaining - principal;

    final allocated = fees + interest + principal;
    return FinancingInstallmentPaymentAllocation(
      installmentId: target.installment.installmentId,
      fees: fees,
      interest: interest,
      principal: principal,
      allocatedAmount: allocated,
      unallocatedAmount: remaining,
    );
  }

  FinancingPaymentAllocationResult allocateAcrossInstallments({
    required Money payment,
    required List<FinancingInstallmentPaymentTarget> targets,
    required DateTime allocationDate,
  }) {
    _validatePayment(payment);

    final eligible = targets.where(_isEligible).toList(growable: false)
      ..sort((a, b) => _compareTargets(a, b, allocationDate));

    var remaining = payment;
    final allocations = <FinancingInstallmentPaymentAllocation>[];

    for (final target in eligible) {
      if (remaining.isZero) {
        break;
      }
      if (target.outstandingTotal.isZero) {
        continue;
      }

      final allocation = allocateToInstallment(
        payment: remaining,
        target: target,
      );
      allocations.add(allocation);
      remaining = allocation.unallocatedAmount;
    }

    final allocated = payment - remaining;
    return FinancingPaymentAllocationResult(
      allocations: List.unmodifiable(allocations),
      allocatedAmount: allocated,
      unallocatedAmount: remaining,
    );
  }

  /// ADR-062 strict overpayment boundary. The calculator may return an
  /// unallocated remainder; a financial payment operation must reject it.
  void requireFullyAllocated(FinancingPaymentAllocationResult result) {
    if (!result.unallocatedAmount.isZero) {
      throw ArgumentError.value(
        result.unallocatedAmount,
        'unallocatedAmount',
        'Payment exceeds eligible financing obligations.',
      );
    }
  }

  bool _isEligible(FinancingInstallmentPaymentTarget target) {
    final status = target.installment.status.trim().toLowerCase();
    if (status == 'settled' || status == 'cancelled' || status == 'superseded') {
      return false;
    }
    _validateTarget(target);
    return !target.outstandingTotal.isZero;
  }

  int _compareTargets(
    FinancingInstallmentPaymentTarget a,
    FinancingInstallmentPaymentTarget b,
    DateTime allocationDate,
  ) {
    final aBucket = _dueBucket(a.installment.dueDate, allocationDate);
    final bBucket = _dueBucket(b.installment.dueDate, allocationDate);
    final bucketComparison = aBucket.compareTo(bBucket);
    if (bucketComparison != 0) {
      return bucketComparison;
    }

    final dateComparison = a.installment.dueDate.compareTo(b.installment.dueDate);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return a.installment.installmentId.compareTo(b.installment.installmentId);
  }

  int _dueBucket(DateTime dueDate, DateTime allocationDate) {
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final allocationDay =
        DateTime(allocationDate.year, allocationDate.month, allocationDate.day);
    if (dueDay.isBefore(allocationDay)) {
      return 0; // overdue
    }
    if (dueDay == allocationDay) {
      return 1; // due today
    }
    return 2; // future
  }

  Money _take(Money remaining, Money outstanding) {
    if (remaining.isZero || outstanding.isZero) {
      return Money.zero;
    }
    if (remaining <= outstanding) {
      return remaining;
    }
    return outstanding;
  }

  void _validatePayment(Money payment) {
    if (!payment.isPositive) {
      throw ArgumentError.value(
        payment,
        'payment',
        'Payment must be greater than zero.',
      );
    }
  }

  void _validateTarget(FinancingInstallmentPaymentTarget target) {
    if (target.outstandingFees.isNegative ||
        target.outstandingInterest.isNegative ||
        target.outstandingPrincipal.isNegative) {
      throw ArgumentError('Outstanding financing components cannot be negative.');
    }
  }
}

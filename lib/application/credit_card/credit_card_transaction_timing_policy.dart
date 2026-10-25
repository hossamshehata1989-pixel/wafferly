import '../../models/financing/financing_contract.dart';
import '../../models/financing/financing_installment.dart';
import 'credit_card_cycle_resolver.dart';
import 'credit_card_due_date_policy.dart';

/// Read-side date policy for the credit-card transaction history.
///
/// The screen must not infer an installment's due month from the purchase date.
/// Installments already carry contractual due dates; ordinary charges instead
/// use the card statement-cycle close date.
abstract final class CreditCardTransactionTimingPolicy {
  /// Returns the actual statement closing date for an ordinary card charge.
  /// When statement settings are incomplete, uses the existing explicit
  /// next-calendar-month fallback rather than reimplementing date arithmetic.
  static DateTime statementDateForPurchase({
    required DateTime purchaseDate,
    required int? statementDay,
  }) {
    if (statementDay == null) {
      return CreditCardCycleResolver.fallbackMonthFor(purchaseDate);
    }
    return CreditCardCycleResolver.closeDateFor(purchaseDate, statementDay);
  }



  /// Resolves the payment date associated with a previously resolved statement
  /// close. When cycle settings are incomplete, retains the established
  /// next-calendar-month fallback based on the original purchase date.
  static DateTime paymentDateForStatementClose({
    required DateTime purchaseDate,
    required DateTime statementCloseDate,
    required int? statementDay,
    required int? paymentDueDay,
    required String dueDateCalculationMethod,
    required int? dueDaysAfterStatement,
    required String weekendHolidayPolicy,
  }) {
    final hasValidDueConfiguration =
        dueDateCalculationMethod == CreditCardDueDatePolicy.fixedOffsetDays
            ? dueDaysAfterStatement != null &&
                dueDaysAfterStatement >= 1 &&
                dueDaysAfterStatement <= 90
            : paymentDueDay != null &&
                paymentDueDay >= 1 &&
                paymentDueDay <= 31;

    if (statementDay == null || !hasValidDueConfiguration) {
      return CreditCardCycleResolver.fallbackMonthFor(purchaseDate);
    }

    return CreditCardDueDatePolicy.forStatementClose(
      statementCloseDate: statementCloseDate,
      calculationMethod: dueDateCalculationMethod,
      paymentDueDay: paymentDueDay,
      dueDaysAfterStatement: dueDaysAfterStatement,
      weekendHolidayPolicy: weekendHolidayPolicy,
    );
  }

  /// Returns the earliest unsettled contractual installment date linked to a
  /// credit-card charge. This includes overdue-but-unsettled installments,
  /// because silently skipping an unpaid past due would mislead the user.
  static DateTime? firstOutstandingInstallmentDueDateForCharge({
    required String chargeId,
    required Iterable<FinancingContract> contracts,
    required Iterable<FinancingInstallment> installments,
  }) {
    final linkedContracts = contracts.where((contract) {
      final state = contract.lifecycleState.trim().toLowerCase();
      return contract.originReference == chargeId &&
          state != 'cancelled' &&
          state != 'canceled' &&
          state != 'terminated';
    }).toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

    if (linkedContracts.isEmpty) return null;
    final contractId = linkedContracts.first.contractId;

    final outstanding = installments.where((item) {
      final status = item.status.trim().toLowerCase();
      return item.contractId == contractId &&
          status != 'settled' &&
          status != 'cancelled' &&
          status != 'canceled' &&
          status != 'superseded' &&
          status != 'terminated';
    }).toList()
      ..sort((a, b) {
        final byDate = a.dueDate.compareTo(b.dueDate);
        return byDate != 0 ? byDate : a.sequence.compareTo(b.sequence);
      });

    return outstanding.isEmpty ? null : outstanding.first.dueDate;
  }
}

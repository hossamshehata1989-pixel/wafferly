/// Shared default-date policy for a newly created Credit Card installment plan.
///
/// The regular Expenses flow already starts card installments in the next
/// calendar month using the card's configured payment-due day. Conversion of
/// an existing charge must use the same default; it must not create an
/// installment due today merely because the conversion screen was opened.
final class CreditCardFirstDueDatePolicy {
  const CreditCardFirstDueDatePolicy._();

  static DateTime defaultFirstDueDate({
    required DateTime referenceDate,
    required int? paymentDueDay,
  }) {
    final targetMonth = DateTime(referenceDate.year, referenceDate.month + 1, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final requestedDay = (paymentDueDay ?? referenceDate.day)
        .clamp(1, lastDay)
        .toInt();
    return DateTime(targetMonth.year, targetMonth.month, requestedDay);
  }
}

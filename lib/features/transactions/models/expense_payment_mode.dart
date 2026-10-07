/// Payment mode selected for a manual expense entry.
///
/// Installment modes are entry-flow state only. They must not be interpreted
/// as a new account or liability by the UI layer.
enum ExpensePaymentMode {
  fullPayment,
  installment,
  downPaymentInstallment,
}

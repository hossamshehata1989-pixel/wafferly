// lib/constants/transaction_constants.dart

/// مصدر المعاملة - لتتبع أصل كل معاملة
class TransactionSource {
  static const String manual = 'manual';
  static const String fromExpense = 'from_expense';
  static const String accountCreation = 'account_creation';
  static const String balanceAdjustment = 'balance_adjustment';
  static const String balanceReconciliation = 'balance_reconciliation';
  static const String tempDebt = 'temp_debt';
  static const String importedCsv = 'imported_csv';
  static const String bankSync = 'bank_sync';
  static const String autoDetected = 'auto_detected';
  static const String scheduled = 'scheduled';

  /// قائمة بكل المصادر (للقوائم والفلترة)
  static const List<String> all = [
    manual,
    fromExpense,
    accountCreation,
    balanceAdjustment,
    balanceReconciliation,
    tempDebt,
    importedCsv,
    bankSync,
    autoDetected,
    scheduled
  ];

  /// هل المصدر تلقائي أم يدوي؟
  static bool isManual(String source) =>
      source == manual || source == fromExpense;
  static bool isAuto(String source) => !isManual(source);
}

/// نوع المعاملة
class TransactionType {
  static const String income = 'income';
  static const String expense = 'expense';
  static const String transfer = 'transfer';
  static const String debt = 'debt';
  static const String initialBalance = 'initial_balance';
  static const String balanceAdjustment = 'balance_adjustment';
  static const String balanceReconciliation = 'balance_reconciliation';

  static const List<String> all = [
    income,
    expense,
    transfer,
    debt,
    initialBalance,
    balanceAdjustment,
    balanceReconciliation,
  ];
}

import '../../models/expense.dart';
import '../../models/transaction.dart';

/// ✅ الدالة الأساسية (كانت ناقصة)
Transaction convertExpenseToTransaction(Expense e) {
  return Transaction(
    id: e.id,
    amount: e.amount,
    type: 'expense',
    fromAccountId: _mapPaymentToAccount(e.paymentMethod),
    toAccountId: null,
    categoryId: e.subCategoryId ?? e.mainCategoryId,
    date: e.date,
    note: e.note,
    isExceptional: e.isExceptional, // 🔥 هنا بالظبط
  );
}

/// 🔒 private helper
String _mapPaymentToAccount(String paymentMethod) {
  switch (paymentMethod) {
    case 'cash':
      return 'cash';
    case 'wallet':
      return 'wallet';
    case 'card':
      return 'credit';
    default:
      return 'cash';
  }
}
// lib/services/transaction_ledger_builder.dart
import 'package:uuid/uuid.dart';
import '../models/ledger_entry.dart';
import '../models/enums/entry_type.dart';
import '../models/enums/ledger_purpose.dart';

/// مسئول عن تحويل intent المعاملة إلى قيود دفترية (LedgerEntries).
/// لا يقوم بحفظ أي شيء في Hive، فقط يُنشئ القيود ككائنات.
class TransactionLedgerBuilder {
  final Uuid _uuid = const Uuid();

  // ==================== Private Helpers ====================

  /// إنشاء قيد واحد (يُستخدم داخلياً)
  LedgerEntry _createEntry({
    required String transactionId,
    required String accountId,
    required EntryType entryType,
    required double amount,
    required DateTime date,
    required LedgerPurpose purpose,
  }) {
    return LedgerEntry(
      id: _uuid.v4(),
      transactionId: transactionId,
      accountId: accountId,
      entryType: entryType,
      amount: amount,
      date: date,
      purpose: purpose,
    );
  }

  // ==================== Public Builders ====================

  /// إنشاء قيود لمصروف (Expense)
  /// - القيد الأول: حساب المصروف (مدين)
  /// - القيد الثاني: الحساب المصدر (دائن)
  List<LedgerEntry> buildExpenseEntries({
    required String transactionId,
    required String expenseAccountId,   // الحساب الذي يتم تحميل المصروف عليه (مدين)
    required String sourceAccountId,    // الحساب الذي يدفع (دائن) – مثل النقدية أو البنك
    required double amount,
    required DateTime date,
  }) {
    return [
      _createEntry(
        transactionId: transactionId,
        accountId: expenseAccountId,
        entryType: EntryType.debit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.expense,
      ),
      _createEntry(
        transactionId: transactionId,
        accountId: sourceAccountId,
        entryType: EntryType.credit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.expense,
      ),
    ];
  }

  /// إنشاء قيود لدخل (Income)
  /// - القيد الأول: الحساب الوجهة (مدين) – الذي يستلم الأموال
  /// - القيد الثاني: حساب الإيرادات (دائن)
  List<LedgerEntry> buildIncomeEntries({
    required String transactionId,
    required String destinationAccountId,  // الحساب الذي يستلم الأموال (مدين)
    required String incomeAccountId,       // حساب الإيرادات (دائن)
    required double amount,
    required DateTime date,
  }) {
    return [
      _createEntry(
        transactionId: transactionId,
        accountId: destinationAccountId,
        entryType: EntryType.debit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.income,
      ),
      _createEntry(
        transactionId: transactionId,
        accountId: incomeAccountId,
        entryType: EntryType.credit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.income,
      ),
    ];
  }

  /// إنشاء قيود لتحويل (Transfer بين حسابين)
  /// - القيد الأول: حساب الوجهة (مدين)
  /// - القيد الثاني: حساب المصدر (دائن)
  List<LedgerEntry> buildTransferEntries({
    required String transactionId,
    required String fromAccountId,   // حساب المصدر (دائن)
    required String toAccountId,     // حساب الوجهة (مدين)
    required double amount,
    required DateTime date,
  }) {
    return [
      _createEntry(
        transactionId: transactionId,
        accountId: toAccountId,
        entryType: EntryType.debit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.transfer,
      ),
      _createEntry(
        transactionId: transactionId,
        accountId: fromAccountId,
        entryType: EntryType.credit,
        amount: amount,
        date: date,
        purpose: LedgerPurpose.transfer,
      ),
    ];
  }
}
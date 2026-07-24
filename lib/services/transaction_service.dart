// lib/services/transaction_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/transaction_constants.dart';
import '../models/transaction.dart';
import 'ledger_service.dart';
import 'ledger_projection_service.dart';

/// خدمة موحدة للتعامل مع المعاملات المالية
/// جميع عمليات CRUD تمر من هنا
class TransactionService {
  static const String _boxName = 'transactions';

  // Private constructor for singleton
  TransactionService._privateConstructor();

  static final TransactionService _instance =
      TransactionService._privateConstructor();

  /// الحصول على نسخة واحدة من الخدمة (Singleton)
  static TransactionService get instance => _instance;

  /// الوصول إلى Box (للقراءة المباشرة فقط عند الحاجة)
  Box<Transaction> get _box => Hive.box<Transaction>(_boxName);

  // ========== Sprint 3C: Category → LedgerAccount Mapping ==========
  final LedgerProjectionService _ledgerProjectionService =
      LedgerProjectionService();
  // ==========================================
  // 📥 Basic CRUD Operations
  // ==========================================

  /// الحصول على جميع المعاملات مرتبة من الأحدث إلى الأقدم
  List<Transaction> getAllTransactions() {
    final transactions = _box.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// الحصول على معاملة بواسطة ID
  Transaction? getById(String id) {
    return _box.get(id);
  }

  /// إضافة معاملة جديدة
  /// 📌 تستخدم put() لضمان استخدام الـ id كـ key
  Future<void> addTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);

    // ========== Passive Ledger Integration (Sprint 3A) ==========
    // لا يؤثر فشل الـ Ledger على نجاح المعاملة الأساسية.
    try {
      await _ledgerProjectionService.project(transaction);
    } catch (e, stack) {
      // فقط طباعة تحذير في console – لا نعطل التطبيق
      print(
        "⚠️ Passive Ledger integration failed for transaction ${transaction.id}: $e",
      );
      print(stack);
    }
    // ============================================================
  }

  /// إنشاء وحفظ LedgerEntries بناءً على نوع المعاملة (passive side‑effect)

  /// تحديث معاملة موجودة
  /// 📌 Sprint 4D: يحذف LedgerEntries القديمة ويعيد إنشائها
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final updated = transaction.touch();

      final ledgerService = LedgerService();

      await ledgerService.deleteEntriesByTransactionId(updated.id);

      await _box.put(updated.id, updated);

      await _ledgerProjectionService.project(updated);

      print("✅ Transaction updated with Ledger sync");
    } catch (e) {
      print("❌ Update transaction failed: $e");
      rethrow;
    }
  }

  /// حذف معاملة
  /// 📌 Sprint 4D: يحذف LedgerEntries المرتبطة أولاً
  Future<void> deleteTransaction(String id) async {
    try {
      final transaction = _box.get(id);

      if (transaction == null) return;

      final ledgerService = LedgerService();

      await ledgerService.deleteEntriesByTransactionId(id);

      await _box.delete(id);

      print("✅ Transaction deleted with Ledger sync");
    } catch (e) {
      print("❌ Delete transaction failed: $e");
      rethrow;
    }
  }

  /// حذف جميع المعاملات (للاختبار أو إعادة تعيين البيانات)
  Future<void> deleteAllTransactions() async {
    await _box.clear();
  }

  // ==========================================
  // 🔍 Query Operations
  // ==========================================

  /// الحصول على المعاملات حسب النوع (income, expense, transfer, etc.)
  List<Transaction> getByType(String type) {
    final transactions = _box.values.where((tx) => tx.type == type).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// الحصول على مصادر الدخل (income transactions only)
  List<Transaction> getIncomeTransactions() {
    return getByType(TransactionType.income);
  }

  /// الحصول على المصروفات (expense transactions only)
  List<Transaction> getExpenseTransactions() {
    return getByType(TransactionType.expense);
  }

  /// الحصول على المعاملات حسب الفئة (categoryId)
  List<Transaction> getByCategory(String categoryId) {
    final transactions = _box.values
        .where((tx) => tx.categoryId == categoryId)
        .toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// الحصول على المعاملات في نطاق زمني محدد
  List<Transaction> getByDateRange(DateTime start, DateTime end) {
    final transactions = _box.values.where((tx) {
      return tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
          tx.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// الحصول على معاملات حساب معين (من أو إلى)
  List<Transaction> getForAccount(String accountId) {
    final transactions = _box.values.where((tx) {
      return tx.fromAccountId == accountId || tx.toAccountId == accountId;
    }).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// التحقق مما إذا كان الحساب لديه معاملات
  bool hasTransactionsForAccount(String accountId) {
    return _box.values.any((tx) {
      return tx.fromAccountId == accountId || tx.toAccountId == accountId;
    });
  }

  // ==========================================
  // 📊 Summary Operations
  // ==========================================

  /// إجمالي المعاملات حسب النوع في نطاق زمني
  double getTotalByType(String type, DateTime start, DateTime end) {
    final transactions = getByDateRange(start, end);
    return transactions
        .where((tx) => tx.type == type)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// إجمالي المصروفات في نطاق زمني
  double getTotalExpenses(DateTime start, DateTime end) {
    return getTotalByType(TransactionType.expense, start, end);
  }

  /// إجمالي الدخل في نطاق زمني
  double getTotalIncome(DateTime start, DateTime end) {
    return getTotalByType(TransactionType.income, start, end);
  }

  /// إجمالي المصروفات العادية (غير الاستثنائية)
  double getNormalExpenses(DateTime start, DateTime end) {
    final transactions = getByDateRange(start, end);
    return transactions
        .where((tx) => tx.type == TransactionType.expense && !tx.isExceptional)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// إجمالي المصروفات الاستثنائية
  double getExceptionalExpenses(DateTime start, DateTime end) {
    final transactions = getByDateRange(start, end);
    return transactions
        .where((tx) => tx.type == TransactionType.expense && tx.isExceptional)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // ==========================================
  // 📈 Analytics Operations
  // ==========================================

  /// تجميع المصروفات حسب الفئة (للمخططات)
  Map<String, double> getExpensesByCategory(DateTime start, DateTime end) {
    final transactions = getByDateRange(start, end);
    final Map<String, double> result = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        if (tx.categoryId != null) {
          result[tx.categoryId!] = (result[tx.categoryId!] ?? 0) + tx.amount;
        }
      }
    }

    return result;
  }

  /// تجميع المصروفات حسب المصدر
  Map<String, double> getExpensesBySource(DateTime start, DateTime end) {
    final transactions = getByDateRange(start, end);
    final Map<String, double> result = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        result[tx.source] = (result[tx.source] ?? 0) + tx.amount;
      }
    }

    return result;
  }

  // ==========================================
  // 🧹 Cleanup & Migration
  // ==========================================

  /// الحصول على المعاملات القديمة (التي لم يتم تحديثها بعد)
  List<Transaction> getLegacyTransactions() {
    final transactions = _box.values.where((tx) => tx.isLegacy).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// عدد المعاملات الكلي
  int get count => _box.length;

  /// التحقق من وجود معاملات
  bool get isEmpty => _box.isEmpty;

  /// التحقق من وجود معاملات
  bool get isNotEmpty => _box.isNotEmpty;
}

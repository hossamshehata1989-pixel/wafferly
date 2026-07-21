// lib/services/transaction_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ledger_entry.dart';
import '../constants/transaction_constants.dart';
import '../models/transaction.dart';
import 'transaction_ledger_builder.dart'; // ✅ Sprint 3A
import 'ledger_service.dart'; // ✅ Sprint 3A
import 'category_ledger_mapper.dart'; // ✅ Sprint 3C

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
  final CategoryLedgerMapper _categoryMapper = CategoryLedgerMapper();

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
      await _createLedgerEntriesForTransaction(transaction);
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
  Future<void> _createLedgerEntriesForTransaction(
    Transaction transaction,
  ) async {
    final builder = TransactionLedgerBuilder();
    final ledgerService = LedgerService();

    // ========== Sprint 3D: Idempotency check ==========
    // منع إنشاء duplicate entries لنفس المعاملة
    final existingEntries = await ledgerService.getEntriesByTransactionId(
      transaction.id,
    );
    if (existingEntries.isNotEmpty) {
      print(
        "ℹ️ Ledger entries already exist for transaction ${transaction.id} – skipping duplicate creation",
      );
      return;
    }
    // ==================================================

    List<LedgerEntry> entries = [];

    switch (transaction.type) {
      // ========== Sprint 3A: Transfer only (safe integration) ==========
      // Transfer uses real fromAccountId and toAccountId (valid ledger accounts)
      case TransactionType.transfer:
        if (transaction.fromAccountId != null &&
            transaction.toAccountId != null) {
          entries = builder.buildTransferEntries(
            transactionId: transaction.id,
            fromAccountId: transaction.fromAccountId!,
            toAccountId: transaction.toAccountId!,
            amount: transaction.amount,
            date: transaction.date,
          );
        } else {
          throw Exception(
            "Transfer transaction missing fromAccountId or toAccountId",
          );
        }
        break;

      // ========== Sprint 3C: Expense with real LedgerAccount ==========
      case TransactionType.expense:
        if (transaction.fromAccountId == null) {
          throw Exception("Expense transaction missing fromAccountId");
        }
        if (transaction.categoryId == null) {
          throw Exception("Expense transaction missing categoryId");
        }

        final expenseLedgerId = _categoryMapper.getLedgerAccountIdForCategory(
          transaction.categoryId!,
        );
        if (expenseLedgerId == null) {
          // Missing mapping: transaction succeeds, ledger entry skipped
          print(
            "⚠️ Missing LedgerAccount mapping for category: ${transaction.categoryId}",
          );
          return;
        }
        entries = builder.buildExpenseEntries(
          transactionId: transaction.id,
          expenseLedgerAccountId: expenseLedgerId,
          sourceAccountId: transaction.fromAccountId!,
          amount: transaction.amount,
          date: transaction.date,
        );
        break;

      // ========== Sprint 3C: Income with real LedgerAccount ==========
      case TransactionType.income:
        if (transaction.toAccountId == null) {
          throw Exception("Income transaction missing toAccountId");
        }
        if (transaction.categoryId == null) {
          throw Exception("Income transaction missing categoryId");
        }

        final incomeLedgerId = _categoryMapper.getLedgerAccountIdForCategory(
          transaction.categoryId!,
        );
        if (incomeLedgerId == null) {
          // Missing mapping: transaction succeeds, ledger entry skipped
          print(
            "⚠️ Missing LedgerAccount mapping for category: ${transaction.categoryId}",
          );
          return;
        }
        entries = builder.buildIncomeEntries(
          transactionId: transaction.id,
          destinationAccountId: transaction.toAccountId!,
          incomeLedgerAccountId: incomeLedgerId,
          amount: transaction.amount,
          date: transaction.date,
        );
        break;

      default:
        // Other types (debt, initialBalance, balanceAdjustment) not in scope for Sprint 3C
        print(
          "ℹ️ Ledger entries not created for transaction type: ${transaction.type}",
        );
        return;
    }

    if (entries.isNotEmpty) {
      await ledgerService.createEntries(entries);
    }
  }

  /// تحديث معاملة موجودة
  /// 📌 Sprint 4D: يحذف LedgerEntries القديمة ويعيد إنشائها
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final updated = transaction.touch();

      final ledgerService = LedgerService();

      await ledgerService.deleteEntriesByTransactionId(updated.id);

      await _box.put(updated.id, updated);

      await _createLedgerEntriesForTransaction(updated);

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

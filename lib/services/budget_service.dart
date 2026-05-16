// lib/services/budget_service.dart

import 'package:hive/hive.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/date_range.dart';
import '../models/enums/budget_period.dart';
import '../constants/transaction_constants.dart';
import '../features/analysis/registry/category_registry.dart';

class BudgetService {
  static const String _boxName = 'budgets';

  Box<Budget> get _box => Hive.box<Budget>(_boxName);

  final Box<Transaction> _txBox = Hive.box<Transaction>('transactions');

  // ==========================================
  // 📥 CRUD Operations
  // ==========================================

  Future<void> createBudget(Budget budget) async {
    await _box.put(budget.id, budget);
  }

  Future<void> updateBudget(Budget budget) async {
    await _box.put(budget.id, budget);
  }

  Future<void> deleteBudget(String id) async {
    await _box.delete(id);
  }

  List<Budget> getAllBudgets() {
    return _box.values.toList();
  }

  List<Budget> getBudgetsByCategory(String categoryId) {
    return _box.values.where((b) => b.categoryId == categoryId).toList();
  }

  Budget? getBudgetById(String id) {
    return _box.get(id);
  }

  // ==========================================
  // 📊 Budget Calculations
  // ==========================================

  /// حساب المبلغ المنفق لفئة معينة في نطاق زمني محدد
  double getSpentAmount(String categoryId, DateTime start, DateTime end) {
    double spent = 0;

    // نهاية اليوم (تشمل اليوم بالكامل)
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    // الحصول على IDs الفئات الفرعية للفئة الرئيسية
    final subCategoryIds = CategoryRegistry.getSubCategories(
      categoryId,
    ).map((e) => e.id).toSet();

    for (final tx in _txBox.values) {
      // تخطي المعاملات خارج النطاق الزمني
      if (tx.date.isBefore(start) || tx.date.isAfter(endOfDay)) {
        continue;
      }

      // تخطي المعاملات التي ليست مصروفات
      if (tx.type != TransactionType.expense) {
        continue;
      }

      // التحقق: الفئة الرئيسية أو فئة فرعية تابعة لها
      final isMainCategory = tx.categoryId == categoryId;
      final isSubCategory =
          tx.subCategoryId != null && subCategoryIds.contains(tx.subCategoryId);

      if (!isMainCategory && !isSubCategory) {
        continue;
      }

      spent += tx.amount;
    }

    return spent;
  }

  /// حساب المبلغ المتبقي لفئة معينة في نطاق زمني محدد
  /// @return null إذا لم توجد ميزانية للفئة، وإلا المبلغ المتبقي (قد يكون سالباً)
  double? getRemainingAmount(String categoryId, DateTime start, DateTime end) {
    // البحث عن الميزانية الخاصة بهذه الفئة
    Budget? budget;
    for (final b in _box.values) {
      if (b.categoryId == categoryId) {
        budget = b;
        break;
      }
    }

    // إذا لم توجد ميزانية، نرجع null
    if (budget == null) {
      return null;
    }

    final spent = getSpentAmount(categoryId, start, end);
    return budget.amount - spent;
  }

  /// الحصول على الميزانية الخاصة بفئة معينة (أول ميزانية تم العثور عليها)
  Budget? getBudgetForCategory(String categoryId) {
    for (final b in _box.values) {
      if (b.categoryId == categoryId) {
        return b;
      }
    }
    return null;
  }

  /// حساب نطاق التاريخ بناءً على نوع الفترة وتاريخ البداية
  DateRange getDateRangeForPeriod(BudgetPeriod period, DateTime referenceDate) {
    switch (period) {
      case BudgetPeriod.weekly:
        final start = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return DateRange(start: start, end: end);

      case BudgetPeriod.monthly:
        final start = DateTime(referenceDate.year, referenceDate.month, 1);
        final end = DateTime(referenceDate.year, referenceDate.month + 1, 0);
        return DateRange(start: start, end: end);

      case BudgetPeriod.yearly:
        final start = DateTime(referenceDate.year, 1, 1);
        final end = DateTime(referenceDate.year, 12, 31);
        return DateRange(start: start, end: end);
    }
  }

  /// حذف جميع الميزانيات (للاختبار)
  Future<void> deleteAllBudgets() async {
    await _box.clear();
  }

  /// عدد الميزانيات الكلي
  int get count => _box.length;
}

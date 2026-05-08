// lib/controllers/transaction_entry_controller.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/balance_service.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../constants/transaction_constants.dart';
import '../config/category_config.dart';

enum SaveStatus { idle, saving }

enum SaveAction {
  none,
  invalidAmount,
  noCategorySelected,
  noAccountSelected,
  insufficientBalance,
  showTempDebtSuccess,
  showNormalSuccess,
}

class SaveResult {
  final bool success;
  final SaveAction action;
  final Map<String, dynamic>? data;

  const SaveResult({
    required this.success,
    this.action = SaveAction.none,
    this.data,
  });
}

class TransactionEntryController extends ChangeNotifier {
  String _amount = "0";
  String _expression = "";
  DateTime _selectedDate = DateTime.now();
  String _note = "";
  String _paymentMethod = "cash";
  String _selectedAccountId = "";
  String _selectedAccountName = "اختر حساب";
  String _selectedCategoryId = "";
  String _selectedTransactionType = TransactionType.expense;
  SaveStatus _saveStatus = SaveStatus.idle;

  static const String tempDebtAccountName = 'دين مؤقت';

  // ==============================
  // 🧠 Getters
  // ==============================

  String get amount => _amount;
  String get expression => _expression;
  DateTime get selectedDate => _selectedDate;
  String get note => _note;
  String get paymentMethod => _paymentMethod;
  String get selectedAccountId => _selectedAccountId;
  String get selectedAccountName => _selectedAccountName;
  String get selectedCategoryId => _selectedCategoryId;
  String get selectedTransactionType => _selectedTransactionType;
  SaveStatus get saveStatus => _saveStatus;

  bool get isIncome => _selectedTransactionType == TransactionType.income;
  bool get isExpense => _selectedTransactionType == TransactionType.expense;

  String get currentCurrency {
    if (_selectedAccountId.isEmpty) return "EGP";
    final box = Hive.box<Account>('accounts');
    final acc = box.get(_selectedAccountId);
    return acc?.currency ?? "EGP";
  }

  // ==============================
  // 💰 Accounts
  // ==============================

  List<Account> get availableAccounts {
    final box = Hive.box<Account>('accounts');
    return box.values
        .where((acc) => acc.bookId == 'default' && !acc.isArchived)
        .toList();
  }

  // ==============================
  // 🧾 Categories
  // ==============================

  bool get hasSubCategories {
    final mainId = _getMainCategoryId(_selectedCategoryId);
    final category = mainCategories.firstWhere(
      (c) => c.id == mainId,
      orElse: () => mainCategories.first,
    );
    return category.subCategories?.isNotEmpty ?? false;
  }

  List<SubCategoryConfig> get currentSubCategories {
    final mainId = _getMainCategoryId(_selectedCategoryId);
    final category = mainCategories.firstWhere(
      (c) => c.id == mainId,
      orElse: () => mainCategories.first,
    );
    return category.subCategories ?? [];
  }

  // ==============================
  // ⚙️ Setters
  // ==============================

  void setAmount(String v) { _amount = v; notifyListeners(); }
  void setExpression(String v) { _expression = v; notifyListeners(); }
  void setSelectedDate(DateTime v) { _selectedDate = v; notifyListeners(); }
  void setNote(String v) { _note = v; notifyListeners(); }
  void setPaymentMethod(String v) { _paymentMethod = v; notifyListeners(); }

  void selectAccount(String id, String name) {
    _selectedAccountId = id;
    _selectedAccountName = name;
    notifyListeners();
  }

  void selectCategory(String id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void setTransactionType(String type) {
    _selectedTransactionType = type;
    notifyListeners();
  }

  // ==============================
  // 🧮 Calculator
  // ==============================

  void onCalculatorTap(String value) {
    if (value == "C") {
      _amount = "0";
      _expression = "";
    } else if (value == "⌫") {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = "0";
        _expression = "";
      }
    } else if (value == "=") {
      final result = double.tryParse(_amount) ?? 0;
      _amount = result.toString();
      _expression = "";
    } else {
      if (_amount == "0") {
        _amount = value;
      } else {
        _amount += value;
      }
    }

    notifyListeners();
  }

  // ==============================
  // 💾 Save
  // ==============================

  Future<SaveResult> validateAndSave({required bool isExceptional}) async {
    if (_saveStatus == SaveStatus.saving) {
      return const SaveResult(success: false);
    }

    _saveStatus = SaveStatus.saving;
    notifyListeners();

    final amountValue = double.tryParse(_amount) ?? 0;

    if (amountValue == 0) {
      return _fail(SaveAction.invalidAmount);
    }

    if (_selectedAccountId.isEmpty) {
      return _fail(SaveAction.noAccountSelected);
    }

    if (isExpense && _selectedCategoryId.isEmpty) {
      return _fail(SaveAction.noCategorySelected);
    }

    // فحص الرصيد فقط في حالة المصروف
    if (isExpense) {
      final balance = BalanceService().getBalance(_selectedAccountId);
      if (amountValue > balance) {
        return _fail(SaveAction.insufficientBalance, {
          "shortage": amountValue - balance
        });
      }
    }

    final success = await _saveTransaction(amountValue, isExceptional);

    _saveStatus = SaveStatus.idle;
    notifyListeners();

    if (success) {
      _resetForm();
      return const SaveResult(success: true, action: SaveAction.showNormalSuccess);
    }

    return const SaveResult(success: false);
  }

  SaveResult _fail(SaveAction action, [Map<String, dynamic>? data]) {
    _saveStatus = SaveStatus.idle;
    notifyListeners();
    return SaveResult(success: false, action: action, data: data);
  }

  // ✅ تم التصحيح: الآن يعتمد على نوع المعاملة (دخل/مصروف)
  Future<bool> _saveTransaction(double amount, bool isExceptional) async {
    final tx = Transaction.create(
      amount: amount,
      type: _selectedTransactionType,
      // اتجاه الحسابات حسب النوع
      fromAccountId: isIncome ? null : _selectedAccountId,
      toAccountId: isIncome ? _selectedAccountId : null,
      // الفئة: للدخل ثابتة "income"، للمصروف من الاختيار
      categoryId: isIncome ? "income" : _selectedCategoryId,
      date: _selectedDate,
      note: _note.isEmpty ? null : _note,
      paymentMethod: _paymentMethod,
      isExceptional: isExceptional,
      currencyCode: currentCurrency,
      source: TransactionSource.manual,
    );

    await TransactionService.instance.addTransaction(tx);
    return true;
  }

  // ==============================
  // 🔥 TEMP DEBT (خاص بالمصروف)
  // ==============================

  Future<void> saveAsTempDebt(double shortage) async {
    // (يمكن تنفيذ منطق إضافي لاحقاً)
  }

  Future<void> addBalanceAndRetry(double shortage) async {
    try {
      final amountValue = double.tryParse(_amount) ?? 0;
      if (amountValue <= 0) return;

      final tempAccount = await _getOrCreateTempDebtAccount();

      // تحويل العجز من حساب الدين إلى الحساب المختار
      await TransactionService.instance.addTransaction(
        Transaction.create(
          amount: shortage,
          type: TransactionType.transfer,
          fromAccountId: tempAccount.id,
          toAccountId: _selectedAccountId,
          categoryId: "debt",
          date: _selectedDate,
          note: "Auto temp debt",
          currencyCode: currentCurrency,
          source: TransactionSource.tempDebt,
        ),
      );

      // تسجيل المصروف بعد توفر الرصيد
      await _saveTransaction(amountValue, false);

      _resetForm();
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
    }
  }

  Future<Account> _getOrCreateTempDebtAccount() async {
    final box = Hive.box<Account>('accounts');

    try {
      return box.values.firstWhere(
        (a) => a.name == tempDebtAccountName && !a.isArchived,
      );
    } catch (_) {
      return await AccountService().createAccount(
        name: tempDebtAccountName,
        type: 'liability',
        currency: currentCurrency,
      );
    }
  }

  // ==============================
  // 🔁 Reset
  // ==============================

  void _resetForm() {
    _amount = "0";
    _expression = "";
    _note = "";
    _selectedCategoryId = "";
    _paymentMethod = "cash";
    notifyListeners();
  }

  // ==============================
  // 🧩 Helpers
  // ==============================

  String _getMainCategoryId(String categoryId) {
    for (final category in mainCategories) {
      if (category.id == categoryId) return category.id;

      for (final sub in category.subCategories ?? []) {
        if (sub.id == categoryId) return category.id;
      }
    }
    return categoryId;
  }
}
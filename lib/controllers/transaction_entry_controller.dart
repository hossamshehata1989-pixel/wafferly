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
import '../config/category_type.dart';

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
  // Getters
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

  /// نوع الفئة بناءً على نوع المعاملة
  CategoryType get categoryType =>
      isIncome ? CategoryType.income : CategoryType.expense;

  /// قائمة الفئات الرئيسية حسب النوع
  List<CategoryConfig> get currentCategories => getCategories(categoryType);

  String get currentCurrency {
    if (_selectedAccountId.isEmpty) return "EGP";
    final box = Hive.box<Account>('accounts');
    final acc = box.get(_selectedAccountId);
    return acc?.currency ?? "EGP";
  }

  // ==============================
  // Accounts
  // ==============================

  List<Account> get availableAccounts {
    final box = Hive.box<Account>('accounts');
    return box.values
        .where((acc) => acc.bookId == 'default' && !acc.isArchived)
        .toList();
  }

  // ==============================
  // SubCategories
  // ==============================

  bool get hasSubCategories {
    final mainId = _getMainCategoryId(_selectedCategoryId);
    final category = currentCategories.firstWhere(
      (c) => c.id == mainId,
      orElse: () => currentCategories.first,
    );
    return category.subCategories?.isNotEmpty ?? false;
  }

  List<SubCategoryConfig> get currentSubCategories {
    final mainId = _getMainCategoryId(_selectedCategoryId);
    final category = currentCategories.firstWhere(
      (c) => c.id == mainId,
      orElse: () => currentCategories.first,
    );
    return category.subCategories ?? [];
  }

  // ==============================
  // Setters
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
    _selectedCategoryId = ""; // Reset category when type changes
    notifyListeners();
  }

  // ==============================
  // Calculator
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
  // Save Logic
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

    // ✅ Category is mandatory for all transaction types
    if (_selectedCategoryId.isEmpty) {
      return _fail(SaveAction.noCategorySelected);
    }

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

  Future<bool> _saveTransaction(double amount, bool isExceptional) async {
    final tx = Transaction.create(
      amount: amount,
      type: _selectedTransactionType,
      fromAccountId: isIncome ? null : _selectedAccountId,
      toAccountId: isIncome ? _selectedAccountId : null,
      categoryId: _selectedCategoryId, // Always use selected category
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
  // Temp Debt Helpers
  // ==============================

  Future<void> saveAsTempDebt(double shortage) async {
    // TODO: Implement temp debt logic when needed
  }

  Future<void> addBalanceAndRetry(double shortage) async {
    try {
      final amountValue = double.tryParse(_amount) ?? 0;
      if (amountValue <= 0) return;

      final tempAccount = await _getOrCreateTempDebtAccount();

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

      await _saveTransaction(amountValue, false);
      _resetForm();
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
    }
  }

  void switchToIncomeMode() {
    _saveStatus = SaveStatus.idle;

    setTransactionType(TransactionType.income);

    notifyListeners();
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
  // Reset
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
  // Helper
  // ==============================

  String _getMainCategoryId(String categoryId) {
    for (final category in currentCategories) {
      if (category.id == categoryId) return category.id;
      for (final sub in category.subCategories ?? []) {
        if (sub.id == categoryId) return category.id;
      }
    }
    return categoryId;
  }
}
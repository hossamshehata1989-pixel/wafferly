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
  noSpendableAccounts,
  insufficientBalance,
  showTempDebtSuccess,
  showNormalSuccess,
}

class SaveResult {
  final bool success;
  final SaveAction action;
  final Map<String, dynamic>? data;
  const SaveResult({required this.success, this.action = SaveAction.none, this.data});
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

  String get currentCurrency {
    if (_selectedAccountId.isEmpty) return "EGP";
    final box = Hive.box<Account>('accounts');
    final acc = box.get(_selectedAccountId);
    return acc?.currency ?? "EGP";
  }

  bool get hasSubCategories {
    final mainId = _getMainCategoryId(_selectedCategoryId);
    final category = mainCategories.firstWhere(
      (c) => c.id == mainId,
      orElse: () => mainCategories.first,
    );
    return category.subCategories != null && category.subCategories!.isNotEmpty;
  }

  List<SubCategoryConfig> get currentSubCategories {
    final mainId = _getMainCategoryId(_selectedCategoryId);
    final category = mainCategories.firstWhere(
      (c) => c.id == mainId,
      orElse: () => mainCategories.first,
    );
    return category.subCategories ?? [];
  }

  List<Account> get spendableAccounts {
    final box = Hive.box<Account>('accounts');
    return box.values.where((acc) => acc.bookId == 'default' && !acc.isArchived).toList();
  }

  bool get hasSpendableAccounts => spendableAccounts.isNotEmpty;

  void setAmount(String newAmount) { _amount = newAmount; notifyListeners(); }
  void setExpression(String newExpression) { _expression = newExpression; notifyListeners(); }
  void setSelectedDate(DateTime date) { _selectedDate = date; notifyListeners(); }
  void setNote(String newNote) { _note = newNote; notifyListeners(); }
  void setPaymentMethod(String method) { _paymentMethod = method; notifyListeners(); }
  void selectAccount(String id, String name) { _selectedAccountId = id; _selectedAccountName = name; notifyListeners(); }
  void selectCategory(String categoryId) { _selectedCategoryId = categoryId; notifyListeners(); }
  void setTransactionType(String type) { _selectedTransactionType = type; notifyListeners(); }

  void onCalculatorTap(String value) {
    if (value == "C") {
      _amount = "0";
      _expression = "";
    } else if (value == "⌫") {
      if (_amount.length > 1) _amount = _amount.substring(0, _amount.length - 1);
      else { _amount = "0"; _expression = ""; }
    } else if (value == "=") {
      final res = double.tryParse(_amount) ?? 0;
      _amount = res.toString();
      _expression = "";
    } else if (value == "+") {
      if (_expression.isEmpty) _expression = _amount + "+";
      else {
        final current = double.tryParse(_amount) ?? 0;
        final total = _calculateExpression();
        _expression = (total + current).toString() + "+";
      }
      _amount = "0";
    } else if (value == ".") {
      if (!_amount.contains(".")) _amount += ".";
    } else {
      if (_amount == "0") _amount = value;
      else _amount += value;
    }
    notifyListeners();
  }

  double _calculateExpression() {
    if (_expression.isEmpty) return 0;
    final parts = _expression.split("+");
    double total = 0;
    for (var p in parts) if (p.isNotEmpty) total += double.tryParse(p) ?? 0;
    return total;
  }

  Future<SaveResult> validateAndSave({required bool isExceptional}) async {
    if (_saveStatus == SaveStatus.saving) return const SaveResult(success: false);
    _saveStatus = SaveStatus.saving;
    notifyListeners();

    final amountValue = double.tryParse(_amount) ?? 0;
    if (amountValue == 0) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(success: false, action: SaveAction.invalidAmount);
    }
    if (_selectedCategoryId.isEmpty) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(success: false, action: SaveAction.noCategorySelected);
    }
    if (!hasSpendableAccounts) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(success: false, action: SaveAction.noSpendableAccounts);
    }
    if (_selectedAccountId.isEmpty) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(success: false, action: SaveAction.noAccountSelected);
    }

    final currentBalance = BalanceService().getBalance(_selectedAccountId);
    final shortage = amountValue - currentBalance;
    if (shortage > 0) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return SaveResult(success: false, action: SaveAction.insufficientBalance, data: {"shortage": shortage, "balance": currentBalance});
    }

    final success = await _saveExpenseDirectly(amountValue, isExceptional);
    _saveStatus = SaveStatus.idle;
    notifyListeners();
    if (success) {
      _resetForm();
      return const SaveResult(success: true, action: SaveAction.showNormalSuccess);
    }
    return const SaveResult(success: false);
  }

  Future<SaveResult> addBalanceAndRetry({required double amountToAdd, required bool isExceptional}) async {
    if (amountToAdd > 0) {
      final tx = Transaction.create(
        amount: amountToAdd,
        type: TransactionType.income,
        toAccountId: _selectedAccountId,
        categoryId: "balance_addition",
        date: DateTime.now(),
        note: "إضافة رصيد يدوي",
        currencyCode: currentCurrency,
        source: TransactionSource.balanceAdjustment,
      );
      await TransactionService.instance.addTransaction(tx);
    }
    return validateAndSave(isExceptional: isExceptional);
  }

  Future<SaveResult> saveAsTempDebt({required bool isExceptional}) async {
    final amountValue = double.tryParse(_amount) ?? 0;
    if (amountValue == 0) return const SaveResult(success: false, action: SaveAction.invalidAmount);
    final debtAccountId = await _ensureTempDebtAccount();
    final transaction = Transaction.create(
      amount: amountValue,
      type: TransactionType.expense,
      fromAccountId: debtAccountId,
      categoryId: _selectedCategoryId,
      date: _selectedDate,
      note: _note.isEmpty ? null : _note,
      paymentMethod: _paymentMethod,
      isExceptional: isExceptional,
      currencyCode: "EGP",
      source: TransactionSource.tempDebt,
    );
    await TransactionService.instance.addTransaction(transaction);
    _resetForm();
    return const SaveResult(success: true, action: SaveAction.showTempDebtSuccess);
  }

  Future<String> _ensureTempDebtAccount() async {
    final box = Hive.box<Account>('accounts');
    final existingAccounts = box.values.where(
      (acc) =>
    acc.type == 'debt' &&
    acc.name == tempDebtAccountName &&
    !acc.isArchived
    ).toList();
    if (existingAccounts.isNotEmpty) {
      return existingAccounts.first.id;
    }
    final accountService = AccountService();
    final newAccount = await accountService.createAccount(
      name: tempDebtAccountName,
      type: 'debt',
      currency: 'EGP',
      notes: 'Auto-created for temporary debt tracking',
    );
    if (newAccount != null) return newAccount.id;
    throw Exception('Failed to create temporary debt account');
  }

  Future<bool> _saveExpenseDirectly(double value, bool isExceptional) async {
    if (_selectedCategoryId.isEmpty) return false;
    final transaction = Transaction.create(
      amount: value,
      type: _selectedTransactionType,
      fromAccountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      date: _selectedDate,
      note: _note.isEmpty ? null : _note,
      paymentMethod: _paymentMethod,
      isExceptional: isExceptional,
      currencyCode: currentCurrency,
      source: TransactionSource.manual,
    );
    await TransactionService.instance.addTransaction(transaction);
    return true;
  }

  void _resetForm() {
    _amount = "0";
    _expression = "";
    _note = "";
    _selectedCategoryId = "";
    _paymentMethod = "cash";
    notifyListeners();
  }

  String _getMainCategoryId(String categoryId) {
    for (final category in mainCategories) {
      if (category.id == categoryId) return category.id;
      if (category.subCategories != null) {
        for (final sub in category.subCategories!) {
          if (sub.id == categoryId) return category.id;
        }
      }
    }
    return categoryId;
  }
}
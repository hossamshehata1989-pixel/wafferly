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
import '../features/analysis/registry/category_registry.dart';
import '../features/members/models/member_model.dart';

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
  Transaction? _editingTransaction;

  String? _selectedMemberId;

  bool get isEditing => _editingTransaction != null;
  // Transfer specific fields
  String _selectedFromAccountId = "";
  String _selectedFromAccountName = "اختر حساب المصدر";
  String _selectedToAccountId = "";
  String _selectedToAccountName = "اختر حساب الوجهة";

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
  String? get selectedMemberId => _selectedMemberId;
  String get selectedTransactionType => _selectedTransactionType;
  SaveStatus get saveStatus => _saveStatus;

  String get selectedFromAccountId => _selectedFromAccountId;
  String get selectedFromAccountName => _selectedFromAccountName;
  String get selectedToAccountId => _selectedToAccountId;
  String get selectedToAccountName => _selectedToAccountName;

  bool get isIncome => _selectedTransactionType == TransactionType.income;
  bool get isExpense => _selectedTransactionType == TransactionType.expense;

  CategoryType get categoryType =>
      isIncome ? CategoryType.income : CategoryType.expense;

  List<CategoryConfig> get currentCategories => getCategories(categoryType);

  String get currentCurrency {
    if (_selectedAccountId.isEmpty) return "EGP";
    final box = Hive.box<Account>('accounts');
    final acc = box.get(_selectedAccountId);
    return acc?.currency ?? "EGP";
  }

  String get transferCurrency {
    if (_selectedFromAccountId.isEmpty) return "EGP";
    final box = Hive.box<Account>('accounts');
    final acc = box.get(_selectedFromAccountId);
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
    return CategoryRegistry.getSubCategories(mainId).isNotEmpty;
  }

  List<SubCategoryConfig> get currentSubCategories {
    final mainId = _getMainCategoryId(_selectedCategoryId);
    return CategoryRegistry.getSubCategories(mainId);
  }

  // ==============================
  // Setters
  // ==============================

  void setAmount(String v) {
    _amount = v;
    notifyListeners();
  }

  void setExpression(String v) {
    _expression = v;
    notifyListeners();
  }

  void setSelectedDate(DateTime v) {
    _selectedDate = v;
    notifyListeners();
  }

  void setNote(String v) {
    _note = v;
    notifyListeners();
  }

  void setPaymentMethod(String v) {
    _paymentMethod = v;
    notifyListeners();
  }

  void selectAccount(String id, String name) {
    _selectedAccountId = id;
    _selectedAccountName = name;
    notifyListeners();
  }

  void selectFromAccount(String id, String name) {
    _selectedFromAccountId = id;
    _selectedFromAccountName = name;
    notifyListeners();
  }

  void selectToAccount(String id, String name) {
    _selectedToAccountId = id;
    _selectedToAccountName = name;
    notifyListeners();
  }

  void selectCategory(String id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void selectMember(String? id) {
    _selectedMemberId = id;
    notifyListeners();
  }

  void setTransactionType(String type) {
    _selectedTransactionType = type;
    _selectedCategoryId = "";

    // Default actor selection
    if (type == TransactionType.expense || type == TransactionType.income) {
      try {
        final owner = Hive.box<MemberModel>(
          'members',
        ).values.firstWhere((m) => m.isOwner && !m.isArchived);

        _selectedMemberId = owner.id;
      } catch (_) {
        _selectedMemberId = null;
      }
    } else {
      _selectedMemberId = null;
    }

    notifyListeners();
  }

  void loadTransaction(Transaction tx) {
    _editingTransaction = tx;

    _amount = tx.amount.toString();
    _selectedDate = tx.date;
    _note = tx.note ?? '';
    _paymentMethod = tx.paymentMethod;

    _selectedTransactionType = tx.type;
    _selectedMemberId = tx.actorMemberId;

    final categoryId = (tx.subCategoryId?.isNotEmpty == true)
        ? tx.subCategoryId!
        : tx.categoryId;

    _selectedCategoryId = categoryId;

    if (tx.type == TransactionType.income) {
      _selectedAccountId = tx.toAccountId ?? '';
    } else {
      _selectedAccountId = tx.fromAccountId ?? '';
    }

    final box = Hive.box<Account>('accounts');

    final account = box.get(_selectedAccountId);

    _selectedAccountName = account?.name ?? "اختر حساب";

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
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(success: false, action: SaveAction.invalidAmount);
    }

    if (_selectedAccountId.isEmpty) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(
        success: false,
        action: SaveAction.noAccountSelected,
      );
    }

    if (_selectedCategoryId.isEmpty) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(
        success: false,
        action: SaveAction.noCategorySelected,
      );
    }

    if (isExpense) {
      final balance = BalanceService().getBalance(_selectedAccountId);
      if (amountValue > balance) {
        _saveStatus = SaveStatus.idle;
        notifyListeners();
        return SaveResult(
          success: false,
          action: SaveAction.insufficientBalance,
          data: {"shortage": amountValue - balance},
        );
      }
    }

    final success = await _saveTransaction(amountValue, isExceptional);

    if (success) {
      _saveStatus = SaveStatus.idle;

      final wasEditing = _editingTransaction != null;

      _editingTransaction = null;

      // Reset فقط أثناء إنشاء معاملة جديدة
      if (!wasEditing) {
        _resetExpenseForm();
      }

      return const SaveResult(
        success: true,
        action: SaveAction.showNormalSuccess,
      );
    }

    _saveStatus = SaveStatus.idle;
    notifyListeners();

    return const SaveResult(success: false);
  }

  // ==============================
  // Category Helpers
  // ==============================

  String _getMainCategoryId(String selectedId) {
    if (CategoryRegistry.isMainCategory(selectedId)) {
      return selectedId;
    }

    if (CategoryRegistry.isSubCategory(selectedId)) {
      final parentId = CategoryRegistry.getParentMainId(selectedId);
      if (parentId != null) {
        return parentId;
      }
    }

    return selectedId;
  }

  bool _isSubCategory(String selectedId) {
    return CategoryRegistry.isSubCategory(selectedId);
  }

  // ==============================
  // Save Transaction
  // ==============================

  Future<bool> _saveTransaction(double amount, bool isExceptional) async {
    final mainCategoryId = _getMainCategoryId(_selectedCategoryId);
    final subCategoryId = _isSubCategory(_selectedCategoryId)
        ? _selectedCategoryId
        : null;

    final tx = Transaction.create(
      amount: amount,
      type: _selectedTransactionType,
      fromAccountId: isIncome ? null : _selectedAccountId,
      toAccountId: isIncome ? _selectedAccountId : null,
      categoryId: mainCategoryId,
      subCategoryId: subCategoryId,
      date: _selectedDate,
      note: _note.isEmpty ? null : _note,
      paymentMethod: _paymentMethod,
      isExceptional: isExceptional,
      currencyCode: currentCurrency,
      source: TransactionSource.manual,
      actorMemberId: _selectedMemberId,
    );

    if (_editingTransaction != null) {
      final updated = _editingTransaction!.copyWith(
        amount: amount,
        type: _selectedTransactionType,
        fromAccountId: isIncome ? null : _selectedAccountId,

        toAccountId: isIncome ? _selectedAccountId : null,

        categoryId: mainCategoryId,

        subCategoryId: subCategoryId,

        date: _selectedDate,

        note: _note.isEmpty ? null : _note,

        paymentMethod: _paymentMethod,

        isExceptional: isExceptional,

        actorMemberId: _selectedMemberId,
      );

      await TransactionService.instance.updateTransaction(updated);
    } else {
      await TransactionService.instance.addTransaction(tx);
    }

    return true;
  }

  // ==============================
  // Transfer Support
  // ==============================

  Future<bool> saveTransfer() async {
    if (_saveStatus == SaveStatus.saving) return false;

    _saveStatus = SaveStatus.saving;
    notifyListeners();

    final amountValue = double.tryParse(_amount) ?? 0;

    try {
      if (amountValue <= 0 ||
          _selectedFromAccountId.isEmpty ||
          _selectedToAccountId.isEmpty ||
          _selectedFromAccountId == _selectedToAccountId) {
        return false;
      }

      final fromBalance = BalanceService().getBalance(_selectedFromAccountId);
      if (amountValue > fromBalance) {
        return false;
      }

      final tx = Transaction.create(
        amount: amountValue,
        type: TransactionType.transfer,
        fromAccountId: _selectedFromAccountId,
        toAccountId: _selectedToAccountId,
        categoryId: "",
        date: _selectedDate,
        note: _note.isEmpty ? null : _note,
        paymentMethod: _paymentMethod,
        isExceptional: false,
        currencyCode: transferCurrency,
        source: TransactionSource.manual,
      );

      await TransactionService.instance.addTransaction(tx);
      _resetTransferForm();
      return true;
    } catch (e) {
      debugPrint("❌ Transfer save failed: $e");
      return false;
    } finally {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
    }
  }

  // ==============================
  // Reset Forms
  // ==============================

  void _resetExpenseForm() {
    _amount = "0";
    _expression = "";
    _note = "";

    _selectedCategoryId = "";

    _selectedAccountId = "";
    _selectedAccountName = "اختر حساب";

    _paymentMethod = "cash";
    _selectedMemberId = null;

    notifyListeners();
  }

  void _resetTransferForm() {
    _amount = "0";
    _expression = "";
    _note = "";
    _selectedFromAccountId = "";
    _selectedFromAccountName = "اختر حساب المصدر";
    _selectedToAccountId = "";
    _selectedToAccountName = "اختر حساب الوجهة";
    _paymentMethod = "cash";
    notifyListeners();
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
      _resetExpenseForm();
    } catch (e) {
      debugPrint("❌ Error: $e");
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
}

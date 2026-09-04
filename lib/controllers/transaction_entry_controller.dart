// lib/controllers/transaction_entry_controller.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/balance_service.dart';
import '../services/transaction_application_service.dart';
import '../constants/transaction_constants.dart';
import '../config/category_config.dart';
import '../config/category_type.dart';
import '../features/analysis/registry/category_registry.dart';
import '../features/members/models/member_model.dart';
import '../features/transactions/calculator/calculator_engine.dart';
import '../features/transactions/calculator/calculator_state.dart';
import '../models/enums/account_enums.dart';
import '../services/reserved_money_service.dart';
import '../features/transactions/models/expense_resolution_option.dart';
import '../services/reserved_money_projection_service.dart';
import '../financial_engine/results/operation_result.dart';
import '../constants/temp_debt_constants.dart';
import '../financial_engine/resolution/resolution.dart';
import '../services/account_service.dart';
import '../features/transactions/models/entry_state.dart';
import '../features/transactions/models/entry_validation_result.dart';

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

  final bool requiresConfirmation;
  final List<Resolution> resolutions;
  final String? errorMessage;

  const SaveResult({
    required this.success,
    this.action = SaveAction.none,
    this.data,
    this.requiresConfirmation = false,
    this.resolutions = const [],
    this.errorMessage,
  });
}

class TransactionEntryController extends ChangeNotifier {
  final TransactionApplicationService _transactionService;
  final AccountService _accountService = AccountService();
  final CalculatorEngine _calculatorEngine = CalculatorEngine();
  CalculatorState _calculatorState = CalculatorState.initial;

  TransactionEntryController({
    required TransactionApplicationService transactionService,
  }) : _transactionService = transactionService {
    _initializeDefaultMember();
    // ✅ الاستماع لتغييرات الحسابات عبر AccountService
    _accountService.accountsListenable.addListener(_syncAccountSelection);
    _syncAccountSelection();
  }

  @override
  void dispose() {
    _accountService.accountsListenable.removeListener(_syncAccountSelection);
    super.dispose();
  }

  void _initializeDefaultMember() {
    try {
      final owner = Hive.box<MemberModel>(
        'members',
      ).values.firstWhere((m) => m.isOwner && !m.isArchived);
      _selectedMemberId = owner.id;
    } catch (_) {
      _selectedMemberId = null;
    }
  }

  // ✅ مزامنة الحساب المختار مع القائمة الحالية
  void _syncAccountSelection() {
    _selectBestAccount();
    // _refreshBalance(); // مستقبلاً
    // _refreshWarnings(); // مستقبلاً
    notifyListeners();
  }

  // ✅ اختيار أفضل حساب (قابلة للتوسع)
  void _selectBestAccount() {
    final accounts = availableAccounts;
    if (accounts.isEmpty) return;

    final exists = accounts.any((a) => a.id == _selectedAccountId);
    if (exists) return;

    final account = accounts.first;
    _selectedAccountId = account.id;
    _selectedAccountName = account.name;
  }

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
  bool _isExceptional = false;
String? _lastErrorMessage;

  bool get isEditing => _editingTransaction != null;
  // Transfer specific fields
  String _selectedFromAccountId = "";
  String _selectedFromAccountName = "اختر حساب المصدر";
  String _selectedToAccountId = "";
  String _selectedToAccountName = "اختر حساب الوجهة";
  String? get lastErrorMessage => _lastErrorMessage;

  // ===========================================

  void _syncCalculatorState() {
    _calculatorState = CalculatorState(
      expression: _amount,
      justCalculated: false,
    );
  }

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
  bool get isExceptional => _isExceptional;

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

  String get transactionDateLabel {
    final now = DateTime.now();

    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Today';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) {
      return 'Yesterday';
    }

    return '${_selectedDate.day}/${_selectedDate.month}';
  }

  // ==============================
  // Accounts
  // ==============================

  // جميع الحسابات النشطة (غير المؤرشفة، وليست الدين المؤقت)
  List<Account> get activeAccounts {
    final box = Hive.box<Account>('accounts');
    return box.values
        .where(
          (acc) =>
              acc.bookId == 'default' &&
              !acc.isArchived &&
              acc.id != tempDebtAccountId,
        )
        .toList();
  }

  // حسابات السيولة فقط (مشتقة من activeAccounts)
  List<Account> get availableAccounts {
    return activeAccounts
        .where((acc) => acc.group == AccountGroup.liquidity)
        .toList();
  }

  // ==============================
  // Members
  // ==============================

  List<MemberModel> get availableMembers {
    return Hive.box<MemberModel>(
      'members',
    ).values.where((m) => !m.isArchived).toList();
  }

  double getTotalLiquidityBalance() {
    double total = 0;
    for (final account in availableAccounts) {
      if (account.group == AccountGroup.liquidity) {
        total += BalanceService().getAvailableBalance(account.id);
      }
    }
    return total;
  }

  double getTotalSavingsBalance() {
    double total = 0;
    for (final account in activeAccounts) {
      if (account.group == AccountGroup.savings) {
        total += BalanceService().getAvailableBalance(account.id);
      }
    }
    return total;
  }

  double getTotalReservedBalance() {
  return ReservedMoneyService().getAll().fold<double>(
    0,
    (sum, item) => sum + item.amount,
  );
}

  List<ExpenseResolutionOption> getLiquidityOptions() {
    final options = <ExpenseResolutionOption>[];
    for (final account in availableAccounts) {
      if (account.group != AccountGroup.liquidity) continue;
      if (account.id == _selectedAccountId) continue;
      final balance = BalanceService().getAvailableBalance(account.id);
      if (balance <= 0) continue;
      options.add(
        ExpenseResolutionOption(
          id: account.id,
          name: account.name,
          amount: balance,
        ),
      );
    }
    return options;
  }

  List<ExpenseResolutionOption> getSavingsOptions() {
    final options = <ExpenseResolutionOption>[];
    for (final account in activeAccounts) {
      if (account.group != AccountGroup.savings) continue;
      final balance = BalanceService().getAvailableBalance(account.id);
      if (balance <= 0) continue;
      options.add(
        ExpenseResolutionOption(
          id: account.id,
          name: account.name,
          amount: balance,
        ),
      );
    }
    return options;
  }

  List<ExpenseResolutionOption> getReservedOptions() {
    final reservedItems = ReservedMoneyService().getAll();
    return reservedItems
        .map(
          (item) => ExpenseResolutionOption(
            id: item.id,
            name: item.title,
            amount: item.amount,
          ),
        )
        .toList();
  }

  double getTotalAvailableBalance() {
    double total = 0;
    for (final account in availableAccounts) {
      total += BalanceService().getAvailableBalance(account.id);
    }
    return total;
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
    _syncCalculatorState();
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

  void selectMember(String memberId) {
    if (_selectedMemberId == memberId) return;

    _selectedMemberId = memberId;
    notifyListeners();
  }

  void toggleExceptional() {
    _isExceptional = !_isExceptional;
    notifyListeners();
  }

  // ==============================
  // Entry State

  EntryState get entryState {
    switch (validationResult) {
      case EntryValidationResult.empty:
        return EntryState.empty;

      case EntryValidationResult.ready:
        return EntryState.readyToSave;

      default:
        return EntryState.draft;
    }
  }

  bool get hasAmount {
    final amount = double.tryParse(_amount);
    return amount != null && amount > 0;
  }

  bool get hasCategory => _selectedCategoryId.isNotEmpty;

  bool get hasAccount => _selectedAccountId.isNotEmpty;

  bool get hasDraftData {
    return _amount != "0" ||
        _selectedCategoryId.isNotEmpty ||
        _note.trim().isNotEmpty ||
        _isExceptional;
  }

  bool get hasValidExpression {
    if (_amount.trim().isEmpty) return false;

    return !RegExp(r'[+\-x*/]$').hasMatch(_amount.trim());
  }

  EntryValidationResult get validationResult {
    if (!hasDraftData) {
      return EntryValidationResult.empty;
    }

    if (!hasValidExpression) {
      return EntryValidationResult.invalidExpression;
    }

    if (!hasAmount) {
      return EntryValidationResult.invalidAmount;
    }

    if (!hasCategory) {
      return EntryValidationResult.noCategory;
    }

    if (!hasAccount) {
      return EntryValidationResult.noAccount;
    }

    return EntryValidationResult.ready;
  }

  // =======================================================
  void setTransactionType(String type) {
    _selectedTransactionType = type;
    _selectedCategoryId = "";
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
    _syncCalculatorState();
    _selectedDate = tx.date;
    _note = tx.note ?? '';
    _paymentMethod = tx.paymentMethod;
    _selectedTransactionType = tx.type;
    _selectedMemberId = tx.actorMemberId;

    final categoryId = (tx.subCategoryId?.isNotEmpty == true)
        ? tx.subCategoryId!
        : (tx.categoryId ?? '');

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

  void onCalculatorTap(String value) {
    final newState = _calculatorEngine.press(_calculatorState, value);

    _calculatorState = newState;
    _amount = newState.expression;

    notifyListeners();
  }

  // ==============================
  // Save Logic
  // ==============================

  SaveResult _handleOperationFailure(Object result) {
    _saveStatus = SaveStatus.idle;
    notifyListeners();

    if (result is ConfirmationRequired) {
      return SaveResult(
        success: false,
        requiresConfirmation: true,
        resolutions: result.options,
      );
    }

    if (result is OperationRejected) {
      return SaveResult(success: false, errorMessage: result.reason);
    }

    if (result is DomainViolationResult) {
      return SaveResult(success: false, errorMessage: result.reason);
    }

    if (result is OperationFailed) {
      return SaveResult(success: false, errorMessage: result.error.toString());
    }

    return const SaveResult(success: false);
  }

  void _onSuccessfulSave() {
    _saveStatus = SaveStatus.idle;

    final wasEditing = _editingTransaction != null;
    _editingTransaction = null;

    if (!wasEditing) {
      _resetExpenseForm();
    }

    notifyListeners();
  }

  Future<SaveResult> submitEntry() async {
    return await saveEntry();
  }

  Future<SaveResult> saveEntry() {
    return validateAndSave(isExceptional: isExpense ? isExceptional : false);
  }

  Future<SaveResult> validateAndSave({required bool isExceptional}) async {
    if (_saveStatus == SaveStatus.saving) {
      return const SaveResult(success: false);
    }

    _saveStatus = SaveStatus.saving;
    notifyListeners();

    switch (validationResult) {
      case EntryValidationResult.empty:
        _saveStatus = SaveStatus.idle;
        notifyListeners();
        return const SaveResult(success: false, action: SaveAction.none);

      case EntryValidationResult.invalidExpression:
        _saveStatus = SaveStatus.idle;
        notifyListeners();
        return const SaveResult(
          success: false,
          action: SaveAction.invalidAmount,
        );

      case EntryValidationResult.invalidAmount:
        _saveStatus = SaveStatus.idle;
        notifyListeners();
        return const SaveResult(
          success: false,
          action: SaveAction.invalidAmount,
        );

      case EntryValidationResult.noCategory:
        _saveStatus = SaveStatus.idle;
        notifyListeners();
        return const SaveResult(
          success: false,
          action: SaveAction.noCategorySelected,
        );

      case EntryValidationResult.noAccount:
        _saveStatus = SaveStatus.idle;
        notifyListeners();
        return const SaveResult(
          success: false,
          action: SaveAction.noAccountSelected,
        );

      case EntryValidationResult.ready:
        break;
    }
    final amountValue = double.parse(_amount);

    if (isExpense) {
      late final OperationResult result;

      if (_editingTransaction != null) {
        final updated = _editingTransaction!.copyWith(
          amount: amountValue,
          fromAccountId: _selectedAccountId,
          categoryId: _getMainCategoryId(_selectedCategoryId),
          subCategoryId: _isSubCategory(_selectedCategoryId)
              ? _selectedCategoryId
              : null,
          date: _selectedDate,
          note: _note.isEmpty ? null : _note,
          paymentMethod: _paymentMethod,
          isExceptional: isExceptional,
          actorMemberId: _selectedMemberId,
        );

        result = await _transactionService.updateExpense(updated);
      } else {
        result = await _transactionService.addExpense(
          sourceAccountId: _selectedAccountId,
          amount: amountValue,
          categoryId: _getMainCategoryId(_selectedCategoryId),
          occurredAt: _selectedDate,
          note: _note.isEmpty ? null : _note,
          isExceptional: isExceptional,
          actorMemberId: _selectedMemberId,
        );
      }

      if (result is OperationSucceeded) {
        _onSuccessfulSave();

        return const SaveResult(
          success: true,
          action: SaveAction.showNormalSuccess,
        );
      }

      return _handleOperationFailure(result);
    }

    if (isIncome) {
      late final OperationResult result;

      if (_editingTransaction != null) {
        final updated = _editingTransaction!.copyWith(
          amount: amountValue,
          toAccountId: _selectedAccountId,
          categoryId: _getMainCategoryId(_selectedCategoryId),
          subCategoryId: _isSubCategory(_selectedCategoryId)
              ? _selectedCategoryId
              : null,
          date: _selectedDate,
          note: _note.isEmpty ? null : _note,
          paymentMethod: _paymentMethod,
          isExceptional: isExceptional,
          actorMemberId: _selectedMemberId,
        );

        result = await _transactionService.updateIncome(updated);
      } else {
        result = await _transactionService.addIncome(
          sourceAccountId: _selectedAccountId,
          amount: amountValue,
          categoryId: _getMainCategoryId(_selectedCategoryId),
          occurredAt: _selectedDate,
          note: _note.isEmpty ? null : _note,
          isExceptional: isExceptional,
          actorMemberId: _selectedMemberId,
        );
      }

      if (result is OperationSucceeded) {
        _onSuccessfulSave();

        return const SaveResult(
          success: true,
          action: SaveAction.showNormalSuccess,
        );
      }

      return _handleOperationFailure(result);
    }

    final success = await _saveTransactionLegacy(amountValue, isExceptional);

    if (success) {
      _saveStatus = SaveStatus.idle;

      final wasEditing = _editingTransaction != null;
      _editingTransaction = null;

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
  // Legacy Save Transaction
  // ==============================

  Future<bool> _saveTransactionLegacy(double amount, bool isExceptional) async {
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

    debugPrint('EDIT DEBUG: editingTransaction = ${_editingTransaction?.id}');

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
      if (updated.type == TransactionType.expense) {
        await _transactionService.updateExpense(updated);
      } else if (updated.type == TransactionType.income) {
        await _transactionService.updateIncome(updated);
      } else if (updated.type == TransactionType.transfer) {
        await _transactionService.updateTransfer(updated);
      }
    } else {
      await _transactionService.addTransaction(tx);
    }

    return true;
  }

  // ==============================
  // Transfer Support
  // ==============================

 Future<bool> saveTransfer() async {
  if (_saveStatus == SaveStatus.saving) return false;

  _saveStatus = SaveStatus.saving;
  _lastErrorMessage = null;
  notifyListeners();

  final amountValue = double.tryParse(_amount) ?? 0;

  try {
    // ==============================
    // Local validation
    // ==============================

    if (amountValue <= 0) {
      _lastErrorMessage = 'Please enter a valid transfer amount.';
      return false;
    }

    if (_selectedFromAccountId.isEmpty) {
      _lastErrorMessage = 'Please select the source account.';
      return false;
    }

    if (_selectedToAccountId.isEmpty) {
      _lastErrorMessage = 'Please select the destination account.';
      return false;
    }

    if (_selectedFromAccountId == _selectedToAccountId) {
      _lastErrorMessage = 'Source and destination accounts must be different.';
      return false;
    }

    // ==============================
    // Financial Engine
    // ==============================

    final result = await _transactionService.addTransfer(
      fromAccountId: _selectedFromAccountId,
      toAccountId: _selectedToAccountId,
      amount: amountValue,
      occurredAt: _selectedDate,
      note: _note.isEmpty ? null : _note,
    );

    if (result is OperationSucceeded) {
      _lastErrorMessage = null;
      _resetTransferForm();
      return true;
    }

    if (result is InsufficientBalance) {
      _lastErrorMessage =
          'Insufficient balance. Available: ${result.available}, '
          'required: ${result.required}.';
      return false;
    }

    if (result is DomainViolationResult) {
      _lastErrorMessage = result.reason;
      return false;
    }

    if (result is OperationRejected) {
      _lastErrorMessage = result.reason;
      return false;
    }

    if (result is OperationFailed) {
      _lastErrorMessage = result.error.toString();
      return false;
    }

    if (result is ConfirmationRequired) {
      _lastErrorMessage =
          'This transfer requires confirmation before it can be completed.';
      return false;
    }

    _lastErrorMessage = 'Transfer could not be completed.';
    return false;
  } catch (e) {
    debugPrint('❌ Transfer save failed: $e');
    _lastErrorMessage = e.toString();
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
    _syncCalculatorState();
    _expression = "";
    _note = "";

    _selectedCategoryId = "";

    _isExceptional = false;
    _selectedDate = DateTime.now();

    _selectBestAccount();

    _paymentMethod = "cash";

    try {
      final owner = Hive.box<MemberModel>(
        'members',
      ).values.firstWhere((m) => m.isOwner && !m.isArchived);
      _selectedMemberId = owner.id;
    } catch (_) {
      _selectedMemberId = null;
    }

    notifyListeners();
  }

  void _resetTransferForm() {
    _amount = "0";
    _syncCalculatorState();
    _expression = "";
    _note = "";
    _selectedFromAccountId = "";
    _selectedFromAccountName = "اختر حساب المصدر";
    _selectedToAccountId = "";
    _selectedToAccountName = "اختر حساب الوجهة";
    _paymentMethod = "cash";
    notifyListeners();
  }
}

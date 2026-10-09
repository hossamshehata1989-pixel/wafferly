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
import '../features/transactions/models/expense_resolution_option.dart';
import '../financial_engine/results/operation_result.dart';
import '../constants/temp_debt_constants.dart';
import '../financial_engine/resolution/resolution.dart';
import '../services/account_service.dart';
import '../application/credit_card/credit_card_financing_application_service.dart';
import '../credit_card/domain/credit_card_profile.dart';
import '../credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import '../features/transactions/models/entry_state.dart';
import '../features/transactions/models/expense_payment_mode.dart';
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
    final selected = _selectedAccountId.isEmpty
        ? null
        : Hive.box<Account>('accounts').get(_selectedAccountId);

    // Preserve an explicitly selected expense source, including savings and
    // credit cards, even though `availableAccounts` remains liquidity-only.
    if (selected != null &&
        !selected.isArchived &&
        selected.bookId == 'default' &&
        ((isCreditCardCharge && selected.type == 'creditCard') ||
            (isExpense && _isExpenseSource(selected)))) {
      return;
    }

    final accounts = availableAccounts;
    if (accounts.isEmpty) return;

    final exists = accounts.any((a) => a.id == _selectedAccountId);
    if (exists) return;

    final account = accounts.first;
    _selectedAccountId = account.id;
    _selectedAccountName = account.name;
  }

  bool _isExpenseSource(Account account) {
    return !account.isArchived &&
        account.bookId == 'default' &&
        (account.group == AccountGroup.liquidity ||
            account.group == AccountGroup.savings ||
            account.type == 'prepaid' ||
            account.type == 'creditCard');
  }

  String _amount = "0";
  String _expression = "";
  DateTime _selectedDate = DateTime.now();
  String _note = "";
  String _paymentMethod = "cash";
  ExpensePaymentMode _expensePaymentMode = ExpensePaymentMode.fullPayment;
  String _selectedAccountId = "";
  String _selectedAccountName = "اختر حساب";
  String _selectedCategoryId = "";
  String _selectedTransactionType = TransactionType.expense;
  SaveStatus _saveStatus = SaveStatus.idle;
  Transaction? _editingTransaction;

  // Stable logical identity for the current installment workflow. It is reused
  // on retries so the Financial Engine sees the same idempotency keys instead
  // of creating a second charge/expense. A changed workflow signature creates
  // a new identity, which preserves the distinction between retry and a new
  // user intent.
  String? _installmentWorkflowId;
  String? _installmentWorkflowSignature;

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
  ExpensePaymentMode get expensePaymentMode => _expensePaymentMode;
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
  bool get isCreditCardCharge =>
      _selectedTransactionType == TransactionType.creditCardCharge;
  bool get isExpense =>
      _selectedTransactionType == TransactionType.expense || isCreditCardCharge;
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

  /// Expense sources are broader than liquidity: savings, prepaid products,
  /// and credit cards can also fund an expense. Financing-only liabilities
  /// and temporary debt are intentionally excluded.
  List<Account> get expenseSourceAccounts {
    return activeAccounts.where(_isExpenseSource).toList();
  }

  List<Account> get savingsAccounts => activeAccounts
      .where((acc) => acc.group == AccountGroup.savings)
      .toList();

  List<Account> get prepaidAccounts => activeAccounts
      .where((acc) => acc.type == 'prepaid')
      .toList();

  List<Account> get creditCardAccounts => activeAccounts
      .where(
        (acc) =>
            acc.group == AccountGroup.liabilities &&
            acc.type == 'creditCard',
      )
      .toList();

  List<Account> get installmentProviderAccounts => activeAccounts
      .where(
        (acc) =>
            acc.group == AccountGroup.liabilities &&
            acc.type == 'installment',
      )
      .toList();

  bool get hasExtendedExpenseSources =>
      savingsAccounts.isNotEmpty ||
      prepaidAccounts.isNotEmpty ||
      creditCardAccounts.isNotEmpty;

  bool get hasExpensePaymentSources => expenseSourceAccounts.isNotEmpty;

  /// Preserve the old 1/2-account toggle, but switch to the richer payment
  /// method sheet once the expense has multiple source families.
  bool get shouldOpenPaymentMethodSheet =>
      isExpense &&
      (availableAccounts.length > 2 || hasExtendedExpenseSources);

  void setExpensePaymentMode(ExpensePaymentMode mode) {
    _expensePaymentMode = mode;
    if (mode == ExpensePaymentMode.fullPayment) {
      final account = _selectedAccountId.isEmpty
          ? null
          : Hive.box<Account>('accounts').get(_selectedAccountId);
      if (account?.type == 'creditCard') {
        _selectedTransactionType = TransactionType.creditCardCharge;
        _paymentMethod = 'credit_card';
      } else if (isExpense) {
        _selectedTransactionType = TransactionType.expense;
        _paymentMethod = 'cash';
      }
    }
    notifyListeners();
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

    final account = Hive.box<Account>('accounts').get(id);
    if (isExpense || isCreditCardCharge) {
      if (account?.type == 'creditCard') {
        _selectedTransactionType = TransactionType.creditCardCharge;
        _paymentMethod = 'credit_card';
      } else if (_editingTransaction == null) {
        _selectedTransactionType = TransactionType.expense;
        _paymentMethod = 'cash';
      }
      _expensePaymentMode = ExpensePaymentMode.fullPayment;
    }

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

  /// Whether the installment action can be opened from the expense entry UI.
  /// Keep this prerequisite decision in the controller, not in the widget.
  bool get canOpenExpenseInstallment => hasCategory && hasAmount;

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
    if (type == TransactionType.expense ||
        type == TransactionType.income ||
        type == TransactionType.creditCardCharge) {
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
    _installmentWorkflowId = null;
    _installmentWorkflowSignature = null;
    _editingTransaction = tx;
    _amount = tx.amount.toString();
    _syncCalculatorState();
    _selectedDate = tx.date;
    _note = tx.note ?? '';
    _paymentMethod = tx.paymentMethod;
    _selectedTransactionType = tx.type;
    _selectedMemberId = tx.actorMemberId;

    // Older Credit Card charges may not have actorMemberId persisted.
    // Keep the Member control visible in Edit by falling back to the owner,
    // exactly like a normal expense entry.
    if (_selectedMemberId == null &&
        (tx.type == TransactionType.expense ||
            tx.type == TransactionType.creditCardCharge)) {
      _initializeDefaultMember();
    }

    final categoryId = (tx.subCategoryId?.isNotEmpty == true)
        ? tx.subCategoryId!
        : (tx.categoryId ?? '');

    _selectedCategoryId = categoryId;

    if (tx.type == TransactionType.income ||
        tx.type == TransactionType.creditCardCharge) {
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

    if (isExpense && _expensePaymentMode != ExpensePaymentMode.fullPayment) {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
      return const SaveResult(
        success: false,
        errorMessage:
            'Complete the installment setup before saving this expense.',
      );
    }

    if (isCreditCardCharge) {
      // Credit-card charges are liability transactions. A new charge is a
      // valid Expense-screen action; editing still corrects the existing
      // charge in place through the Financial Engine.
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
        result = await _transactionService.updateCreditCardCharge(updated);
      } else {
        result = await _transactionService.addCreditCardCharge(
          creditCardAccountId: _selectedAccountId,
          amount: amountValue,
          categoryId: _getMainCategoryId(_selectedCategoryId),
          occurredAt: _selectedDate,
          currencyCode: currentCurrency,
          note: _note.isEmpty ? null : _note,
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

    _saveStatus = SaveStatus.idle;
    _lastErrorMessage =
        'Unsupported transaction type: $_selectedTransactionType';
    notifyListeners();

    return SaveResult(success: false, errorMessage: _lastErrorMessage);
  }

  /// Saves a manual expense financed through a Credit Card installment plan.
  ///
  /// A no-down-payment plan creates one Credit Card charge for the purchase
  /// amount and then creates the financing contract/schedule around that
  /// already-posted charge. A down-payment plan creates a normal expense for
  /// the amount paid now, then charges only the financed remainder to the
  /// Credit Card before creating the financing contract.
  ///
  /// Financing persistence itself is contractual state; the actual financial
  /// effects always go through [TransactionApplicationService]/FinancialEngine.
  /// Saves a manual expense financed through a Credit Card installment plan.
  ///
  /// The workflow has one stable logical identity. Each financial mutation
  /// derives its own stable idempotency key from that identity, while financing
  /// conversion derives its contractual identity from the immutable charge id.
  /// This means a retry after a successful write reuses the same result instead
  /// of creating a second transaction or second financing contract.
  Future<SaveResult> saveCreditCardInstallment({
    required String creditCardAccountId,
    required int installmentCount,
    required DateTime firstDueDate,
    double downPayment = 0,
    String? downPaymentAccountId,
  }) async {
    if (_saveStatus == SaveStatus.saving) {
      return const SaveResult(success: false);
    }

    _lastErrorMessage = null;
    _saveStatus = SaveStatus.saving;
    notifyListeners();

    try {
      final amountValue = double.tryParse(_amount) ?? 0;
      final categoryId = _getMainCategoryId(_selectedCategoryId);

      if (amountValue <= 0) {
        return const SaveResult(
          success: false,
          action: SaveAction.invalidAmount,
          errorMessage: 'Enter a valid purchase amount.',
        );
      }

      if (_selectedCategoryId.isEmpty) {
        return const SaveResult(
          success: false,
          action: SaveAction.noCategorySelected,
          errorMessage: 'Select a category first.',
        );
      }

      final card = Hive.box<Account>('accounts').get(creditCardAccountId);
      if (card == null ||
          card.isArchived ||
          card.bookId != 'default' ||
          card.type != 'creditCard') {
        return const SaveResult(
          success: false,
          errorMessage: 'Select a valid Credit Card.',
        );
      }

      if (installmentCount < 1) {
        return const SaveResult(
          success: false,
          errorMessage: 'Installment count must be at least 1.',
        );
      }

      if (downPayment < 0 || downPayment >= amountValue) {
        return const SaveResult(
          success: false,
          errorMessage:
              'Down payment must be greater than or equal to 0 and less than the purchase amount.',
        );
      }

      if (downPayment > 0) {
        if (downPaymentAccountId == null || downPaymentAccountId.isEmpty) {
          return const SaveResult(
            success: false,
            errorMessage: 'Select an account for the down payment.',
          );
        }

        final source = Hive.box<Account>('accounts').get(downPaymentAccountId);
        if (source == null ||
            source.isArchived ||
            source.bookId != 'default' ||
            !_isExpenseSource(source)) {
          return const SaveResult(
            success: false,
            errorMessage:
                'Select an eligible spendable source for the down payment.',
          );
        }

        if (source.currency != card.currency) {
          return SaveResult(
            success: false,
            errorMessage:
                'The down-payment source must use the financing card currency (${card.currency}).',
          );
        }

        // A down payment can use either another Credit Card or the same card
        // that will finance the remainder. The workflow posts these as two
        // distinct, idempotent charge operations: only the financed charge is
        // converted to installments; the down-payment charge stays ordinary.
        // When both charges use the same card, its available credit must cover
        // the entire purchase amount before we begin either write.
        if (source.type == 'creditCard') {
          final isSameFinancingCard = source.id == creditCardAccountId;
          final profile = await _findCreditCardProfile(source.id);
          if (profile == null) {
            return const SaveResult(
              success: false,
              errorMessage:
                  'The selected down-payment Credit Card has no valid card profile.',
            );
          }

          final outstanding = _creditCardOutstanding(source.id);
          final availableCredit =
              (profile.creditLimit.toDouble() - outstanding)
                  .clamp(0.0, double.infinity)
                  .toDouble();
          final requiredCredit = isSameFinancingCard ? amountValue : downPayment;
          if (requiredCredit > availableCredit + 0.000001) {
            return SaveResult(
              success: false,
              errorMessage: isSameFinancingCard
                  ? 'The selected card must have enough available credit for the full purchase amount (${availableCredit.toStringAsFixed(2)} available).'
                  : "Down payment exceeds the selected card's available credit (${availableCredit.toStringAsFixed(2)}).",
            );
          }
        }
      }

      final financedAmount = amountValue - downPayment;
      if (financedAmount <= 0) {
        return const SaveResult(
          success: false,
          errorMessage: 'The financed amount must be greater than zero.',
        );
      }

      final workflowSignature = _buildInstallmentWorkflowSignature(
        creditCardAccountId: creditCardAccountId,
        amount: amountValue,
        categoryId: categoryId,
        installmentCount: installmentCount,
        firstDueDate: firstDueDate,
        downPayment: downPayment,
        downPaymentAccountId: downPaymentAccountId,
      );
      final workflowId = _ensureInstallmentWorkflowId(workflowSignature);

      final chargeIdempotencyKey =
          'installment:$workflowId:credit-card-charge';
      final downPaymentIdempotencyKey =
          'installment:$workflowId:down-payment';

      debugPrint(
        'INSTALLMENT WORKFLOW: id=$workflowId signature=$workflowSignature',
      );

      // 1) Post the financed Credit Card charge first.
      //
      // This ordering is intentional. If contractual conversion fails, the
      // charge remains a recoverable staged financial effect. Retrying with the
      // same idempotency key returns the same transaction instead of posting a
      // second charge. We never delete a successful financial mutation merely
      // because a downstream contractual step needs to be retried.
      final chargeResult = await _transactionService.addCreditCardCharge(
        creditCardAccountId: creditCardAccountId,
        amount: financedAmount,
        categoryId: categoryId,
        occurredAt: _selectedDate,
        currencyCode: card.currency,
        note: _note.isEmpty
            ? 'Installment purchase'
            : '${_note} • Installment',
        actorMemberId: _selectedMemberId,
        idempotencyKey: chargeIdempotencyKey,
        isExceptional: isExceptional,
      );

      if (chargeResult is! OperationSucceeded) {
        return _handleOperationFailure(chargeResult);
      }

      if (chargeResult.summary.createdTransactionIds.isEmpty) {
        return const SaveResult(
          success: false,
          errorMessage:
              'Credit Card charge succeeded but returned no transaction identity.',
        );
      }

      final chargeTransactionId =
          chargeResult.summary.createdTransactionIds.first;
      final charge = Hive.box<Transaction>('transactions').get(
        chargeTransactionId,
      );
      if (charge == null) {
        return const SaveResult(
          success: false,
          errorMessage:
              'Credit Card charge succeeded but could not be reloaded for financing conversion.',
        );
      }

      // 2) Convert the already-posted charge. The conversion layer uses IDs
      // derived from charge.id, so retries converge on the same contract,
      // schedule, rule and installments.
      try {
        final conversionResult =
            await CreditCardFinancingApplicationService().convertCharge(
          charge: charge,
          installmentCount: installmentCount,
          firstDueDate: firstDueDate,
        );

        debugPrint(
          'INSTALLMENT CONVERSION: alreadyCompleted=${conversionResult.alreadyCompleted} '
          'contract=${conversionResult.contract.contractId} '
          'installments=${conversionResult.installments.length}',
        );
      } catch (error) {
        // Do NOT delete the successful charge. The stable charge idempotency
        // key plus charge-derived conversion identities make the workflow
        // safely retryable without a second financial effect.
        debugPrint('INSTALLMENT CONVERSION RETRYABLE FAILURE: $error');
        return SaveResult(
          success: false,
          errorMessage:
              'Credit Card charge was saved, but installment conversion is pending. '
              'Press Continue to retry safely. Details: $error',
        );
      }

      // 3) Optional Down Payment. It may come from liquidity/savings/prepaid
      // (normal Expense) or from a DIFFERENT Credit Card (card charge). Both
      // mutations use the same stable workflow-derived idempotency key.
      if (downPayment > 0) {
        final downPaymentSource =
            Hive.box<Account>('accounts').get(downPaymentAccountId);

        if (downPaymentSource == null) {
          return const SaveResult(
            success: false,
            errorMessage: 'The down-payment source is no longer available.',
          );
        }

        final OperationResult result;
        if (downPaymentSource.type == 'creditCard') {
          result = await _transactionService.addCreditCardCharge(
            creditCardAccountId: downPaymentSource.id,
            amount: downPayment,
            categoryId: categoryId,
            occurredAt: _selectedDate,
            currencyCode: downPaymentSource.currency,
            note: _note.isEmpty
                ? 'Down payment'
                : '${_note} • Down payment',
            actorMemberId: _selectedMemberId,
            idempotencyKey: downPaymentIdempotencyKey,
            isExceptional: isExceptional,
          );
        } else {
          result = await _transactionService.addExpense(
            sourceAccountId: downPaymentSource.id,
            amount: downPayment,
            categoryId: categoryId,
            occurredAt: _selectedDate,
            note: _note.isEmpty ? 'Down payment' : '${_note} • Down payment',
            isExceptional: isExceptional,
            actorMemberId: _selectedMemberId,
            idempotencyKey: downPaymentIdempotencyKey,
          );
        }

        if (result is! OperationSucceeded) {
          return SaveResult(
            success: false,
            errorMessage:
                'Installment plan was saved, but the down payment is pending. '
                'Press Continue to retry safely. Details: ${result is OperationFailed ? result.error : result}',
          );
        }
      }

      _onSuccessfulSave();
      return const SaveResult(
        success: true,
        action: SaveAction.showNormalSuccess,
      );
    } catch (error) {
      // No blanket deletion here. Any successful financial mutation may now
      // be durable behind an idempotency key and/or financing conversion. The
      // safe recovery path is retrying the same logical workflow, not creating
      // compensating duplicate-looking deletes from the UI layer.
      debugPrint('INSTALLMENT WORKFLOW ERROR: $error');
      _lastErrorMessage = error.toString();
      notifyListeners();
      return SaveResult(success: false, errorMessage: _lastErrorMessage);
    } finally {
      _saveStatus = SaveStatus.idle;
      notifyListeners();
    }
  }

  String _buildInstallmentWorkflowSignature({
    required String creditCardAccountId,
    required double amount,
    required String categoryId,
    required int installmentCount,
    required DateTime firstDueDate,
    required double downPayment,
    required String? downPaymentAccountId,
  }) {
    return [
      creditCardAccountId,
      amount.toStringAsFixed(2),
      categoryId,
      installmentCount.toString(),
      firstDueDate.toIso8601String(),
      downPayment.toStringAsFixed(2),
      downPaymentAccountId ?? '',
      _selectedDate.toIso8601String(),
      _note,
      _selectedMemberId ?? '',
      _isExceptional.toString(),
    ].join('|');
  }

  String _ensureInstallmentWorkflowId(String signature) {
    if (_installmentWorkflowId != null &&
        _installmentWorkflowSignature == signature) {
      return _installmentWorkflowId!;
    }

    final generated =
        'iw-${DateTime.now().microsecondsSinceEpoch}-${signature.hashCode.abs()}';
    _installmentWorkflowId = generated;
    _installmentWorkflowSignature = signature;
    return generated;
  }

  Future<CreditCardProfile?> _findCreditCardProfile(String accountId) async {
    try {
      final repository = HiveCreditCardProfileRepository(
        Hive.box<CreditCardProfile>('credit_card_profiles'),
      );
      return repository.findByAccountId(accountId);
    } catch (_) {
      return null;
    }
  }

  double _creditCardOutstanding(String accountId) {
    try {
      final balance = BalanceService().getBalance(accountId);
      return balance < 0 ? -balance : 0.0;
    } catch (_) {
      return double.infinity;
    }
  }

  String? _findLatestTransactionId({
    required String type,
    String? fromAccountId,
    String? toAccountId,
    required double amount,
    required DateTime occurredAt,
    required DateTime createdAfter,
  }) {
    final candidates = Hive.box<Transaction>('transactions').values.where((tx) {
      if (tx.type != type) return false;
      if (fromAccountId != null && tx.fromAccountId != fromAccountId) {
        return false;
      }
      if (toAccountId != null && tx.toAccountId != toAccountId) return false;
      if ((tx.amount - amount).abs() > 0.000001) return false;
      if (tx.date != occurredAt) return false;
      return !tx.createdAt.isBefore(createdAfter);
    }).toList();

    candidates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    try {
      return candidates.first.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _rollbackCreatedTransaction(String? transactionId) async {
    if (transactionId == null) return;
    try {
      final result = await _transactionService.delete(transactionId);
      if (result is! OperationSucceeded) {
        debugPrint(
          'INSTALLMENT ROLLBACK FAILED for $transactionId: $result',
        );
      }
    } catch (error) {
      debugPrint('INSTALLMENT ROLLBACK ERROR for $transactionId: $error');
    }
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
        _lastErrorMessage =
            'Source and destination accounts must be different.';
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
    _installmentWorkflowId = null;
    _installmentWorkflowSignature = null;
    _amount = "0";
    _syncCalculatorState();
    _expression = "";
    _note = "";

    _selectedCategoryId = "";

    _isExceptional = false;
    _selectedDate = DateTime.now();
    _expensePaymentMode = ExpensePaymentMode.fullPayment;
    _paymentMethod = "cash";

    _selectBestAccount();

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

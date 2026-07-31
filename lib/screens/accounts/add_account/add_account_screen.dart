// lib/screens/accounts/add_account_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/account_service.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/enums/section_type.dart';
import 'package:wafferly/l10n/app_localizations.dart';

import '../../../theme/account_asset_resolver.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/accounts/account_icon_picker.dart';
import '../../../widgets/accounts/account_type_section.dart';
import 'package:wafferly/models/enums/account_type_option.dart';
import '../../../widgets/accounts/account_details_section.dart';
import '../../../widgets/accounts/account_preview_card.dart';
import '../../../shared/widgets/wafferly_section_title.dart';
import 'package:wafferly/controllers/accounts/account_form_controller.dart';

class AddAccountScreen extends StatefulWidget {
  final SectionType? sectionType;
  final Account? accountToEdit;

  // NEW
  final String? initialAccountType;

  const AddAccountScreen({
    super.key,
    this.sectionType,
    this.accountToEdit,
    this.initialAccountType,
  });

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  //======================================================
  // Controllers
  //======================================================

  final _form = AccountFormController();

  //======================================================
  // State
  //======================================================

  final _formKey = GlobalKey<FormState>();
  String _selectedType = '';
  String? _selectedIcon;
  String _selectedCurrency = 'EGP';
  bool _isSaving = false;
  double _oldBalance = 0;

  //======================================================
  // Computed Properties
  //======================================================

  List<AccountTypeOption> get _accountTypes {
    final section = widget.sectionType ?? SectionType.liquidity;
    switch (section) {
      case SectionType.liquidity:
        return [
          AccountTypeOption.cash,
          AccountTypeOption.bank,
          AccountTypeOption.wallet,
          AccountTypeOption.debitCard,
        ];
      case SectionType.liabilities:
        return [
          AccountTypeOption.debt,
          AccountTypeOption.loan,
          AccountTypeOption.creditCard,
          AccountTypeOption.installment,
        ];
      case SectionType.investments:
        return [
          AccountTypeOption.investment,
          AccountTypeOption.gold,
          AccountTypeOption.stocks,
          AccountTypeOption.certificates,
        ];
      case SectionType.receivable:
        return [AccountTypeOption.lent, AccountTypeOption.rosca];
      case SectionType.savings:
        return [AccountTypeOption.realSaving, AccountTypeOption.savingCircle];
    }
  }

  String get _sectionTitle => widget.accountToEdit != null
      ? 'Edit Account'
      : 'Add Account - $_sectionName';

  String get _sectionName {
    switch (widget.sectionType ?? SectionType.liquidity) {
      case SectionType.liquidity:
        return 'Liquidity ';
      case SectionType.liabilities:
        return 'liabilities';
      case SectionType.investments:
        return 'Investments';
      case SectionType.receivable:
        return 'Recievable';
      case SectionType.savings:
        return 'Savings';
    }
  }

  String get _buttonText =>
      widget.accountToEdit != null ? 'Update Account' : 'Create Account';

  //======================================================
  // Lifecycle
  //======================================================

  @override
  void initState() {
    super.initState();

    if (widget.accountToEdit != null) {
      _form.nameController.text = widget.accountToEdit!.name;
      _selectedType = widget.accountToEdit!.type;
      _selectedIcon = widget.accountToEdit!.icon;
      _selectedCurrency = widget.accountToEdit!.currency;
      _form.notesController.text = widget.accountToEdit!.notes ?? '';
      _loadCurrentBalance();
    } else {
      _selectedType = widget.initialAccountType ?? '';
      _selectedIcon = null;
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  //======================================================
  // UI
  //======================================================

  Color _getButtonColor() {
    switch (widget.sectionType ?? SectionType.liquidity) {
      case SectionType.liquidity:
        return Colors.green;
      case SectionType.liabilities:
        return Colors.red;
      case SectionType.investments:
        return Colors.orange;
      case SectionType.receivable:
        return Colors.cyan;
      case SectionType.savings:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _sectionTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.accountToEdit != null
            ? [
                IconButton(
                  icon: const Icon(Icons.archive, color: Colors.red),
                  onPressed: _showCloseAccountDialog,
                ),
              ]
            : null,
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(child: _buildContent(t)),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeSection(t),
          _buildIconSection(),
          _buildDetailsSection(t),
          _buildPreviewSection(),
        ],
      ),
    );
  }

  //======================================================
  // Section Builders (UI sub‑methods)
  //======================================================

  Widget _buildTypeSection(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WafferlySectionTitle(title: 'Account Type'),
        const SizedBox(height: 12),
        AccountTypeSection(
          types: _accountTypes,
          selectedType: _selectedType,
          isEditMode: widget.accountToEdit != null,
          t: t,
          onChanged: (type) {
            setState(() {
              _selectedType = type;
              _selectedIcon = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildIconSection() {
    if (_selectedType.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AccountIconPicker(
        icons: AccountAssetResolver.iconsForType(
          widget.sectionType ?? SectionType.liquidity,
          _selectedType,
        ),
        selectedIcon: _selectedIcon,
        onChanged: (icon) {
          setState(() {
            _selectedIcon = icon;
          });
        },
      ),
    );
  }

  Widget _buildDetailsSection(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AccountDetailsSection(
        nameController: _form.nameController,
        balanceController: _form.balanceController,
        notesController: _form.notesController,
        isEditMode: widget.accountToEdit != null,
        selectedCurrency: _selectedCurrency,
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AccountPreviewCard(
        accountName: _form.nameController.text,
        iconAsset: _selectedIcon,
        accountType: _selectedType,
        currency: _selectedCurrency,
        balance: _form.balanceController.text,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accountToEdit != null
                ? Colors.blue
                : (_getButtonColor()),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  //======================================================
  // Dialogs
  //======================================================

  void _showTypeChangeWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text(
          '⚠️ Cannot Change Account Type',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Account type cannot be changed after creation.\n\nIf you need a different account type, please create a new account.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showCloseAccountDialog() async {
    final hasTransactions = await _checkIfAccountHasTransactions();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Row(
          children: [
            Icon(Icons.archive, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Close Account',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to close "${widget.accountToEdit?.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (hasTransactions)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.history, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This account has transaction history. Closing it will preserve all records.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'This account can be restored later.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: _closeAccount,
            child: const Text(
              'Archive Account',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  //======================================================
  // Account Actions
  //======================================================

  Future<void> _saveAccount() async {
    if (!_form.validate(_formKey)) return;
    if (_selectedType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    final data = _form.data;

    if (widget.accountToEdit != null) {
      final updatedAccount = Account(
        id: widget.accountToEdit!.id,
        bookId: _getCurrentBookId(),
        memberId: widget.accountToEdit!.memberId,
        name: data.name,
        type: _selectedType,
        currency: _selectedCurrency,
        createdAt: widget.accountToEdit!.createdAt,
        group: widget.accountToEdit!.group,
        isArchived: widget.accountToEdit!.isArchived,
        notes: data.notes,
        icon: _selectedIcon,
        nature: widget.accountToEdit!.nature,
      );
      await AccountService().updateAccount(updatedAccount);
      await _updateBalance(widget.accountToEdit!.id, data.balance);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.name} updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      final accountService = AccountService();
      final newAccount = await accountService.createAccount(
        name: data.name,
        type: _selectedType,
        currency: _selectedCurrency,
        icon: _selectedIcon,
        notes: data.notes,
      );

      if (data.balance != 0) {
        final isLiability = widget.sectionType == SectionType.liabilities;
        final initialBalanceAmount = isLiability ? -data.balance : data.balance;
        final initialTransaction = Transaction.create(
          amount: initialBalanceAmount.abs(),
          type: TransactionType.initialBalance,
          fromAccountId: initialBalanceAmount < 0 ? newAccount.id : null,
          toAccountId: initialBalanceAmount > 0 ? newAccount.id : null,
          categoryId: "initial_balance",
          date: DateTime.now(),
          note: "Initial balance",
          isExceptional: false,
          paymentMethod: _selectedType,
          currencyCode: _selectedCurrency,
          source: TransactionSource.accountCreation,
        );
        await Hive.box<Transaction>(
          'transactions',
        ).put(initialTransaction.id, initialTransaction);
      }

      if (mounted) {
        final formattedAmount = NumberFormat(
          "#,###",
        ).format(data.balance.toInt());
        final amountText = widget.sectionType == SectionType.liabilities
            ? '$formattedAmount EGP (Debt)'
            : '$formattedAmount EGP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.name} added with $amountText'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _closeAccount() async {
    if (widget.accountToEdit == null) return;
    setState(() => _isSaving = true);
    try {
      await AccountService().archiveAccount(widget.accountToEdit!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account archived. You can restore it later from settings.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error archiving account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _checkIfAccountHasTransactions() async {
    if (widget.accountToEdit == null) return false;
    final transactionsBox = Hive.box<Transaction>('transactions');
    return transactionsBox.values.any(
      (t) =>
          t.fromAccountId == widget.accountToEdit!.id ||
          t.toAccountId == widget.accountToEdit!.id,
    );
  }

  //======================================================
  // Balance
  //======================================================

  Future<void> _loadCurrentBalance() async {
    if (widget.accountToEdit != null) {
      final balance = BalanceService().getBalance(widget.accountToEdit!.id);
      _oldBalance = balance;
      _form.balanceController.text = balance.abs().toString();
    }
  }

  Future<void> _updateBalance(String accountId, double newBalance) async {
    final difference = newBalance - _oldBalance;
    if (difference == 0) return;
    final adjustmentTransaction = Transaction.create(
      amount: difference.abs(),
      type: TransactionType.balanceAdjustment,
      fromAccountId: difference < 0 ? accountId : null,
      toAccountId: difference > 0 ? accountId : null,
      categoryId: "balance_adjustment",
      date: DateTime.now(),
      note: "Manual balance adjustment",
      isExceptional: false,
      paymentMethod: _selectedType,
      currencyCode: _selectedCurrency,
      source: TransactionSource.balanceAdjustment,
    );
    await Hive.box<Transaction>(
      'transactions',
    ).put(adjustmentTransaction.id, adjustmentTransaction);
  }

  //======================================================
  // Helpers
  //======================================================

  String _getCurrentBookId() => "default";
}

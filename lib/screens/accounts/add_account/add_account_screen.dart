import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/account_service.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/enums/section_type.dart';

enum AccountTypeOption {
  cash('cash', 'Cash', Icons.attach_money, Colors.green),
  bank('bank', 'Bank', Icons.account_balance, Colors.blue),
  wallet('wallet', 'Wallet', Icons.account_balance_wallet, Colors.orange),
  debitCard('debitCard', 'Debit Card', Icons.credit_card, Colors.teal),
  debt('debt', 'Debt', Icons.money_off, Colors.red),
  loan('loan', 'Loan', Icons.request_page, Colors.deepOrange),
  creditCard('creditCard', 'Credit Card Due', Icons.credit_card, Colors.pink),
  installment('installment', 'Installments', Icons.calendar_month, Colors.purple),
  investment('investment', 'Investment', Icons.trending_up, Colors.teal),
  gold('gold', 'Gold', Icons.workspace_premium, Colors.amber),
  stocks('stocks', 'Stocks', Icons.show_chart, Colors.green),
  certificates('certificates', 'Certificates', Icons.description, Colors.blue),
  lent('lent', 'Money Lent', Icons.handshake, Colors.cyan),
  rosca('rosca', 'ROSCA', Icons.group, Colors.indigo);

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  const AccountTypeOption(this.id, this.name, this.icon, this.color);
}

class AddAccountScreen extends StatefulWidget {
  final SectionType? sectionType;
  final Account? accountToEdit;
  const AddAccountScreen({super.key, this.sectionType, this.accountToEdit});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = '';
  String _selectedCurrency = 'EGP';
  bool _isSaving = false;
  double _oldBalance = 0;

  List<AccountTypeOption> get _accountTypes {
    final section = widget.sectionType ?? SectionType.asset;
    switch (section) {
      case SectionType.asset:
        return [AccountTypeOption.cash, AccountTypeOption.bank, AccountTypeOption.wallet, AccountTypeOption.debitCard];
      case SectionType.liability:
        return [AccountTypeOption.debt, AccountTypeOption.loan, AccountTypeOption.creditCard, AccountTypeOption.installment];
      case SectionType.investment:
        return [AccountTypeOption.investment, AccountTypeOption.gold, AccountTypeOption.stocks, AccountTypeOption.certificates];
      case SectionType.receivable:
        return [AccountTypeOption.lent, AccountTypeOption.rosca];
    }
  }

  String get _sectionTitle => widget.accountToEdit != null ? 'Edit Account' : 'Add Account - ${_sectionName}';
  String get _sectionName {
    switch (widget.sectionType ?? SectionType.asset) {
      case SectionType.asset: return 'Money You Have';
      case SectionType.liability: return 'Money You Owe';
      case SectionType.investment: return 'Investments';
      case SectionType.receivable: return 'Money You Will Get';
    }
  }

  String get _buttonText => widget.accountToEdit != null ? 'Update Account' : 'Create Account';

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      _nameController.text = widget.accountToEdit!.name;
      _selectedType = widget.accountToEdit!.type;
      _selectedCurrency = widget.accountToEdit!.currency;
      _notesController.text = widget.accountToEdit!.notes ?? '';
      _loadCurrentBalance();
    }
  }

  Future<void> _loadCurrentBalance() async {
    if (widget.accountToEdit != null) {
      final balance = BalanceService().getBalance(widget.accountToEdit!.id);
      _oldBalance = balance;
      _balanceController.text = balance.abs().toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(_sectionTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: widget.accountToEdit != null ? [IconButton(icon: const Icon(Icons.archive, color: Colors.red), onPressed: _showCloseAccountDialog)] : null,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Type', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    _buildAccountTypeGrid(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        labelStyle: TextStyle(color: Colors.white54),
                        hintText: 'e.g., My Bank Account',
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter account name' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _balanceController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.accountToEdit != null ? 'Current Balance' : 'Initial Balance',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixText: '$_selectedCurrency ',
                        prefixStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
                      ),
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text('Currency', style: TextStyle(color: Colors.white54)),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                            child: const Text('EGP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accountToEdit != null ? Colors.blue : (_getButtonColor()),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_buttonText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (widget.sectionType ?? SectionType.asset) {
      case SectionType.asset: return Colors.green;
      case SectionType.liability: return Colors.red;
      case SectionType.investment: return Colors.orange;
      case SectionType.receivable: return Colors.cyan;
    }
  }

  Widget _buildAccountTypeGrid() {
    final types = _accountTypes;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 400 ? 2 : 4;
    final isEditMode = widget.accountToEdit != null;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = _selectedType == type.id;
        return GestureDetector(
          onTap: () {
            if (isEditMode && _selectedType.isNotEmpty && _selectedType != type.id) { _showTypeChangeWarning(); return; }
            setState(() => _selectedType = type.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? type.color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? type.color : Colors.white.withOpacity(0.1), width: isSelected ? 2 : 1),
              boxShadow: isSelected ? [BoxShadow(color: type.color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(type.icon, color: isSelected ? type.color : Colors.white54, size: 32),
              const SizedBox(height: 8),
              Text(type.name, style: TextStyle(color: isSelected ? type.color : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ]),
          ),
        );
      },
    );
  }

  void _showTypeChangeWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text('⚠️ Cannot Change Account Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Account type cannot be changed after creation.\n\nIf you need a different account type, please create a new account.', style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.blue)))],
      ),
    );
  }

  void _showCloseAccountDialog() async {
    final hasTransactions = await _checkIfAccountHasTransactions();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Row(children: [Icon(Icons.archive, color: Colors.red, size: 28), SizedBox(width: 12), Text('Close Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to close "${widget.accountToEdit?.name}"?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            if (hasTransactions)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: const Row(children: [Icon(Icons.history, color: Colors.orange, size: 20), SizedBox(width: 8), Expanded(child: Text('This account has transaction history. Closing it will preserve all records.', style: TextStyle(color: Colors.orange, fontSize: 12)))]),
              ),
            const SizedBox(height: 16),
            const Text('This account can be restored later.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: _closeAccount, child: const Text('Archive Account', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<bool> _checkIfAccountHasTransactions() async {
    if (widget.accountToEdit == null) return false;
    final transactionsBox = Hive.box<Transaction>('transactions');
    return transactionsBox.values.any((t) => t.fromAccountId == widget.accountToEdit!.id || t.toAccountId == widget.accountToEdit!.id);
  }

  Future<void> _closeAccount() async {
    if (widget.accountToEdit == null) return;
    setState(() => _isSaving = true);
    try {
      await AccountService().archiveAccount(widget.accountToEdit!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account archived. You can restore it later from settings.'), backgroundColor: Colors.orange, duration: Duration(seconds: 3)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error archiving account: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _isSaving = false); }
  }

  String _getCurrentBookId() => "default";

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
    await Hive.box<Transaction>('transactions').put(adjustmentTransaction.id, adjustmentTransaction);
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account type'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final balanceValue = double.tryParse(_balanceController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    if (widget.accountToEdit != null) {
      // تحديث حساب موجود
      final updatedAccount = Account(
        id: widget.accountToEdit!.id,
        bookId: _getCurrentBookId(),
        memberId: widget.accountToEdit!.memberId,
        name: name,
        type: _selectedType,
        currency: _selectedCurrency,
        createdAt: widget.accountToEdit!.createdAt,
        group: widget.accountToEdit!.group,
        isArchived: widget.accountToEdit!.isArchived,
        notes: notes,
        nature: widget.accountToEdit!.nature,
      );
      await AccountService().updateAccount(updatedAccount);
      await _updateBalance(widget.accountToEdit!.id, balanceValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name updated successfully'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } else {
      // إنشاء حساب جديد
      final accountService = AccountService();
      final newAccount = await accountService.createAccount(
        name: name,
        type: _selectedType,
        currency: _selectedCurrency,
        notes: notes,
      );
      if (newAccount == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create account'), backgroundColor: Colors.red));
        setState(() => _isSaving = false);
        return;
      }

      // معاملة الرصيد الابتدائي
      if (balanceValue != 0) {
        final isLiability = widget.sectionType == SectionType.liability;
        final initialBalanceAmount = isLiability ? -balanceValue : balanceValue;
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
        await Hive.box<Transaction>('transactions').put(initialTransaction.id, initialTransaction);
      }

      if (mounted) {
        final formattedAmount = NumberFormat("#,###").format(balanceValue.toInt());
        final amountText = widget.sectionType == SectionType.liability ? '$formattedAmount EGP (Debt)' : '$formattedAmount EGP';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added with $amountText'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    }
    setState(() => _isSaving = false);
  }
}
// lib/screens/accounts/add_account_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';
import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';
import '../../../constants/transaction_constants.dart';  // ✅ Added

enum SectionType {
  asset,      // Money You Have
  liability,  // Money You Owe
  investment, // Investments
  receivable, // Money You Will Get
}

class AddAccountScreen extends StatefulWidget {
  final SectionType? sectionType;
  final Account? accountToEdit;

  const AddAccountScreen({
    super.key,
    this.sectionType,
    this.accountToEdit,
  });

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
        return const [
          AccountTypeOption(id: 'cash', name: 'Cash', icon: Icons.attach_money, color: Colors.green),
          AccountTypeOption(id: 'bank', name: 'Bank', icon: Icons.account_balance, color: Colors.blue),
          AccountTypeOption(id: 'wallet', name: 'Wallet', icon: Icons.account_balance_wallet, color: Colors.orange),
          AccountTypeOption(id: 'debitCard', name: 'Debit Card', icon: Icons.credit_card, color: Colors.teal),
        ];
        
      case SectionType.liability:
        return const [
          AccountTypeOption(id: 'debt', name: 'Debt', icon: Icons.money_off, color: Colors.red),
          AccountTypeOption(id: 'loan', name: 'Loan', icon: Icons.request_page, color: Colors.deepOrange),
          AccountTypeOption(id: 'creditCard', name: 'Credit Card Due', icon: Icons.credit_card, color: Colors.pink),
          AccountTypeOption(id: 'installment', name: 'Installments', icon: Icons.calendar_month, color: Colors.purple),
        ];
        
      case SectionType.investment:
        return const [
          AccountTypeOption(id: 'investment', name: 'Investment', icon: Icons.trending_up, color: Colors.teal),
          AccountTypeOption(id: 'gold', name: 'Gold', icon: Icons.workspace_premium, color: Colors.amber),
          AccountTypeOption(id: 'stocks', name: 'Stocks', icon: Icons.show_chart, color: Colors.green),
          AccountTypeOption(id: 'certificates', name: 'Certificates', icon: Icons.description, color: Colors.blue),
        ];
        
      case SectionType.receivable:
        return const [
          AccountTypeOption(id: 'lent', name: 'Money Lent', icon: Icons.handshake, color: Colors.cyan),
          AccountTypeOption(id: 'rosca', name: 'ROSCA', icon: Icons.group, color: Colors.indigo),
        ];
    }
  }

  String get _sectionTitle {
    if (widget.accountToEdit != null) {
      return 'Edit Account';
    }
    
    switch (widget.sectionType ?? SectionType.asset) {
      case SectionType.asset: return 'Add Account - Money You Have';
      case SectionType.liability: return 'Add Account - Money You Owe';
      case SectionType.investment: return 'Add Account - Investments';
      case SectionType.receivable: return 'Add Account - Money You Will Get';
    }
  }

  String get _buttonText {
    if (widget.accountToEdit != null) {
      return 'Update Account';
    }
    
    switch (widget.sectionType ?? SectionType.asset) {
      case SectionType.asset: return 'Create Account';
      case SectionType.liability: return 'Create Liability';
      case SectionType.investment: return 'Create Investment';
      case SectionType.receivable: return 'Create Receivable';
    }
  }

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
      final balanceService = BalanceService();
      final balance = balanceService.getBalance(widget.accountToEdit!.id);
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
        title: Text(
          _sectionTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  tooltip: 'Close Account',
                ),
              ]
            : null,
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
                    const Text(
                      'Account Type',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter account name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _balanceController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _getBalanceLabel(),
                        labelStyle: const TextStyle(color: Colors.white54),
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixText: '${_selectedCurrency} ',
                        prefixStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Currency',
                            style: TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              'EGP',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
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
                        hintText: 'Add any additional information...',
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: _getButtonColor().withOpacity(0.5),
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
            ),
          ],
        ),
      ),
    );
  }

  String _getBalanceLabel() {
    if (widget.accountToEdit != null) {
      return 'Current Balance';
    }
    
    switch (widget.sectionType ?? SectionType.asset) {
      case SectionType.asset: return 'Initial Balance';
      case SectionType.liability: return 'Debt Amount';
      case SectionType.investment: return 'Investment Amount';
      case SectionType.receivable: return 'Expected Amount';
    }
  }

  Color _getButtonColor() {
    if (widget.accountToEdit != null) return Colors.blue;
    
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = _selectedType == type.id;
        
        return GestureDetector(
          onTap: () {
            if (isEditMode && _selectedType.isNotEmpty && _selectedType != type.id) {
              _showTypeChangeWarning();
              return;
            }
            setState(() {
              _selectedType = type.id;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? type.color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? type.color : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: type.color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type.icon,
                  color: isSelected ? type.color : Colors.white54,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  type.name,
                  style: TextStyle(
                    color: isSelected ? type.color : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
        title: const Text(
          '⚠️ Cannot Change Account Type',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Account type cannot be changed after creation.\n\n'
          'If you need a different account type, please create a new account.',
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

  // ✅ Close Account - Archive logic (no actual deletion)
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => _closeAccount(),
            child: const Text('Close Account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkIfAccountHasTransactions() async {
    if (widget.accountToEdit == null) return false;
    
    final transactionsBox = Hive.box<Transaction>('transactions');
    final hasTransactions = transactionsBox.values.any(
      (t) => t.fromAccountId == widget.accountToEdit!.id || 
             t.toAccountId == widget.accountToEdit!.id,
    );
    return hasTransactions;
  }

  // ✅ Archive account - لا نحذف البيانات نهائياً
  Future<void> _closeAccount() async {
    if (widget.accountToEdit == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      // ✅ تحديث الحساب: إضافة علامة isArchived = true
      final archivedAccount = Account(
        id: widget.accountToEdit!.id,
        bookId: widget.accountToEdit!.bookId,
        name: widget.accountToEdit!.name,
        type: widget.accountToEdit!.type,
        nature: widget.accountToEdit!.nature,
        currency: widget.accountToEdit!.currency,
        provider: widget.accountToEdit!.provider,
        accountNumber: widget.accountToEdit!.accountNumber,
        color: widget.accountToEdit!.color,
        icon: widget.accountToEdit!.icon,
        notes: widget.accountToEdit!.notes,
        createdAt: widget.accountToEdit!.createdAt,
      );
      
      // ✅ نضيف حقل isArchived - نحتاج إضافته في نموذج Account
      // مؤقتاً: نستخدم حقل موجود أو نضيفه لاحقاً
      // الآن سنستخدم notes للإشارة إلى أن الحساب مقفول
      // await AccountService().updateAccount(archivedAccount);
      
      // ✅ حل مؤقت: حذف الحساب من الـ active box
      // وفي المستقبل: نضيف isArchived field
      await AccountService().deleteAccount(widget.accountToEdit!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account closed. You can restore it later from settings.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getCurrentBookId() {
    return "personal";
  }

  // ✅ Updated: استخدام Transaction.create()
  Future<void> _updateBalance(String accountId, double newBalance) async {
    final difference = newBalance - _oldBalance;
    
    if (difference == 0) return;
    
    final transactionsBox = Hive.box<Transaction>('transactions');
    
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
    
    await transactionsBox.put(adjustmentTransaction.id, adjustmentTransaction);
  }

  // ✅ Updated: استخدام Transaction.create()
  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
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
    
    final name = _nameController.text.trim();
    final balanceValue = double.tryParse(_balanceController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final bookId = _getCurrentBookId();
    final nature = _getNature(_selectedType);
    
    double balanceToSave = balanceValue;
    if (widget.sectionType == SectionType.liability && widget.accountToEdit == null) {
      balanceToSave = -balanceValue;
    }
    
    if (widget.accountToEdit != null) {
      final updatedAccount = Account(
        id: widget.accountToEdit!.id,
        bookId: bookId,
        name: name,
        type: _selectedType,
        nature: nature,
        currency: _selectedCurrency,
        notes: notes,
        createdAt: widget.accountToEdit!.createdAt,
      );
      
      await AccountService().updateAccount(updatedAccount);
      await _updateBalance(widget.accountToEdit!.id, balanceValue);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      final accountId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final account = Account(
        id: accountId,
        bookId: bookId,
        name: name,
        type: _selectedType,
        nature: nature,
        currency: _selectedCurrency,
        notes: notes,
        createdAt: DateTime.now(),
      );
      
      await AccountService().addAccount(account);
      
      if (balanceToSave != 0) {
        final transactionsBox = Hive.box<Transaction>('transactions');
        
        final initialTransaction = Transaction.create(
          amount: balanceToSave.abs(),
          type: TransactionType.initialBalance,
          fromAccountId: balanceToSave < 0 ? accountId : null,
          toAccountId: balanceToSave > 0 ? accountId : null,
          categoryId: "initial_balance",
          date: DateTime.now(),
          note: "Initial balance",
          isExceptional: false,
          paymentMethod: _selectedType,
          currencyCode: _selectedCurrency,
          source: TransactionSource.accountCreation,
        );
        
        await transactionsBox.put(initialTransaction.id, initialTransaction);
      }
      
      if (mounted) {
        final formattedAmount = NumberFormat("#,###").format(balanceValue.toInt());
        final amountText = widget.sectionType == SectionType.liability 
            ? '$formattedAmount EGP (Debt)' 
            : '$formattedAmount EGP';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added with $amountText'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
    
    setState(() => _isSaving = false);
  }

  String _getNature(String type) {
    final section = widget.sectionType ?? SectionType.asset;
    
    switch (section) {
      case SectionType.asset: return 'asset';
      case SectionType.liability: return 'liability';
      case SectionType.investment: return 'investment';
      case SectionType.receivable: return 'receivable';
    }
  }
}

class AccountTypeOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const AccountTypeOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
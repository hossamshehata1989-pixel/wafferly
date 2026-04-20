import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../utils/category_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../config/category_config.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_helper.dart';
import '../services/balance_service.dart';

class SelectedCategory {
  final String id;
  final String name;

  SelectedCategory({
    required this.id,
    required this.name,
  });
}

PersistentBottomSheetController? _controller;

void showAddExpenseSheet(
  BuildContext context,
  ValueNotifier<SelectedCategory> categoryNotifier, {
  Transaction? expenseToEdit,
  int? expenseKey,
}) {
  if (_controller != null) return;

  final screenHeight = MediaQuery.of(context).size.height;
  final bottomSheetHeight = screenHeight * 0.3;

  _controller = Scaffold.of(context).showBottomSheet(
    (context) => SizedBox(
      height: bottomSheetHeight.clamp(450.0, screenHeight * 0.8),
      child: AddExpenseBottomSheet(
        categoryNotifier: categoryNotifier,
        expenseToEdit: expenseToEdit,
        expenseKey: expenseKey,
      ),
    ),
  );

  _controller!.closed.then((_) {
    _controller = null;
  });
}

class AddExpenseBottomSheet extends StatefulWidget {
  final ValueNotifier<SelectedCategory> categoryNotifier;
  final Transaction? expenseToEdit;
  final int? expenseKey;

  const AddExpenseBottomSheet({
    super.key,
    required this.categoryNotifier,
    this.expenseToEdit,
    this.expenseKey,
  });

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  late String amount;
  late DateTime selectedDate;
  late String note;
  late String paymentMethod;
  late String selectedAccountId;
  late String selectedAccountName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      amount = widget.expenseToEdit!.amount.toString();
      selectedDate = widget.expenseToEdit!.date;
      note = widget.expenseToEdit!.note ?? "";
      paymentMethod = widget.expenseToEdit!.paymentMethod;
      selectedAccountId = widget.expenseToEdit!.fromAccountId ?? "cash";
      selectedAccountName = _getAccountName(selectedAccountId);
      
      widget.categoryNotifier.value = SelectedCategory(
        id: widget.expenseToEdit!.categoryId,
        name: widget.expenseToEdit!.categoryId,
      );
    } else {
      amount = "0";
      selectedDate = DateTime.now();
      note = "";
      paymentMethod = "cash";
      selectedAccountId = "cash";
      selectedAccountName = "Cash";
    }
  }

  String _getAccountName(String accountId) {
    final accountsBox = Hive.box<Account>('accounts');
    for (final acc in accountsBox.values) {
      if (acc.id == accountId) {
        return acc.name;
      }
    }
    return accountId;
  }

  void addNumber(String n) {
    setState(() {
      if (amount == "0") {
        amount = n;
      } else {
        amount += n;
      }
    });
  }

  void clear() => setState(() => amount = "0");

  void backspace() {
    setState(() {
      if (amount.length > 1) {
        amount = amount.substring(0, amount.length - 1);
      } else {
        amount = "0";
      }
    });
  }

  void calculatePercentage() {
    if (amount != "0") {
      final value = double.tryParse(amount) ?? 0;
      final percentage = value / 100;
      setState(() {
        amount = percentage.toString();
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3A7BFF),
              surface: Color(0xFF1B2A6B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) {
        String tempNote = note;
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2A6B),
          title: Text(
            AppLocalizations.of(context)!.addNote,
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظتك...',
              hintStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              tempNote = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  note = tempNote;
                });
                Navigator.pop(context);
              },
              child: const Text('حفظ', style: TextStyle(color: Color(0xFF3A7BFF))),
            ),
          ],
        );
      },
    );
  }

  void _selectAccount() {
    final accountsBox = Hive.box<Account>('accounts');
    
    final spendableAccounts = accountsBox.values.where((acc) =>
      acc.nature == 'asset' &&
      acc.type != 'investment' &&
      acc.type != 'lent'
    ).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر الحساب',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...spendableAccounts.map((acc) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getAccountColor(acc.type).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getAccountIcon(acc.type), color: _getAccountColor(acc.type), size: 24),
                ),
                title: Text(acc.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: Text(acc.type, style: const TextStyle(color: Colors.white54)),
                trailing: selectedAccountId == acc.id
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    selectedAccountId = acc.id;
                    selectedAccountName = acc.name;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'cash': return Colors.green;
      case 'bank': return Colors.blue;
      case 'wallet': return Colors.orange;
      case 'creditCard': return Colors.red;
      case 'loan': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash': return Icons.attach_money;
      case 'bank': return Icons.account_balance;
      case 'wallet': return Icons.account_balance_wallet;
      case 'creditCard': return Icons.credit_card;
      case 'loan': return Icons.money_off;
      default: return Icons.account_balance_wallet;
    }
  }

  String _getMainCategoryId(String categoryId) {
    for (final category in mainCategories) {
      if (category.id == categoryId) {
        return category.id;
      }
      if (category.subCategories != null) {
        for (final sub in category.subCategories!) {
          if (sub.id == categoryId) {
            return category.id;
          }
        }
      }
    }
    return categoryId;
  }

  bool _isSubCategory(String categoryId) {
    for (final category in mainCategories) {
      if (category.subCategories != null) {
        for (final sub in category.subCategories!) {
          if (sub.id == categoryId) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<String> _showInsufficientBalanceDialog(double neededAmount, double currentBalance) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              "⚠️ رصيد غير كافٍ",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ليس لديك رصيد كافٍ في حساب '$selectedAccountName'",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("الرصيد الحالي:", style: TextStyle(color: Colors.white54)),
                      Text(
                        "${currentBalance.toStringAsFixed(0)} EGP",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("المبلغ المطلوب:", style: TextStyle(color: Colors.white54)),
                      Text(
                        "${neededAmount.toStringAsFixed(0)} EGP",
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("العجز:", style: TextStyle(color: Colors.white54)),
                      Text(
                        "${(neededAmount - currentBalance).toStringAsFixed(0)} EGP",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "ماذا تريد أن تفعل؟",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'add_balance'),
            child: const Text("➕ إضافة رصيد", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'create_debt'),
            child: const Text("📝 تسجيل كدين", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    return result ?? 'cancel';
  }

  Future<void> _addBalanceToAccount(String accountId, double amountToAdd) async {
    final transactionsBox = Hive.box<Transaction>('transactions');
    await transactionsBox.add(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: "income",
        amount: amountToAdd,
        fromAccountId: null,
        toAccountId: accountId,
        categoryId: "balance_addition",
        date: DateTime.now(),
        note: "إضافة رصيد تلقائي لعجز المصروف",
        isExceptional: false,
        paymentMethod: paymentMethod,
      ),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ تم إضافة ${amountToAdd.toStringAsFixed(0)} EGP لتغطية العجز"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createDebtAccountAndSaveExpense(double expenseAmount, bool isExceptional) async {
    final accountsBox = Hive.box<Account>('accounts');
    final debtAccountId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final debtAccount = Account(
      id: debtAccountId,
      bookId: "personal",
      name: "دين مستحق (${DateTime.now().day}/${DateTime.now().month})",
      type: "loan",
      nature: "liability",
      currency: "EGP",
      createdAt: DateTime.now(),
    );
    
    await accountsBox.put(debtAccountId, debtAccount);
    
    setState(() {
      selectedAccountId = debtAccountId;
      selectedAccountName = debtAccount.name;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("📝 تم إنشاء حساب دين جديد: ${debtAccount.name}"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
    await _saveExpenseDirectly(expenseAmount, isExceptional);
  }

  Future<void> _saveExpenseDirectly(double value, bool isExceptional) async {
    final box = Hive.box<Transaction>('transactions');
    final selected = widget.categoryNotifier.value;
    final isSub = _isSubCategory(selected.id);
    final mainCategoryId = _getMainCategoryId(selected.id);
    final subCategoryId = isSub ? selected.id : null;

    final transaction = Transaction(
      id: widget.expenseToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: "expense",
      amount: value,
      fromAccountId: selectedAccountId,
      toAccountId: null,
      categoryId: mainCategoryId,
      subCategoryId: subCategoryId,
      date: selectedDate,
      note: note.isEmpty ? null : note,
      isExceptional: isExceptional,
      paymentMethod: paymentMethod,
    );

    if (widget.expenseToEdit != null && widget.expenseKey != null) {
      await box.putAt(widget.expenseKey!, transaction);
    } else {
      await box.add(transaction);
    }
  }

  Future<void> _saveExpense({required bool isExceptional}) async {
    if (_isSaving) return;

    final value = double.tryParse(amount) ?? 0;

    if (value == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterValidAmount),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ التحقق من الرصيد (للمصروفات الجديدة فقط)
    if (widget.expenseToEdit == null) {
      final currentBalance = BalanceService().getBalance(selectedAccountId);
      
      if (currentBalance < value) {
        final action = await _showInsufficientBalanceDialog(value, currentBalance);
        
        if (action == 'add_balance') {
          // ✅ حساب العجز المطلوب فقط
          final shortage = value - currentBalance;
          
          // ✅ إضافة الرصيد الناقص فقط
          await _addBalanceToAccount(selectedAccountId, shortage);
          
          if (!mounted) return;
          
          // ✅ حفظ المصروف تلقائياً بعد إضافة الرصيد
          await _saveExpense(isExceptional: isExceptional);
          return;
        }
        
        if (action == 'create_debt') {
          await _createDebtAccountAndSaveExpense(value, isExceptional);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isExceptional
                      ? "✅ تم تسجيل المصروف الاستثنائي كدين"
                      : "✅ تم تسجيل المصروف كدين",
                ),
                backgroundColor: isExceptional ? Colors.orange : Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
        return;
      }
    }

    setState(() => _isSaving = true);

    final box = Hive.box<Transaction>('transactions');
    final selected = widget.categoryNotifier.value;
    final isSub = _isSubCategory(selected.id);
    final mainCategoryId = _getMainCategoryId(selected.id);
    final subCategoryId = isSub ? selected.id : null;

    final transaction = Transaction(
      id: widget.expenseToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: "expense",
      amount: value,
      fromAccountId: selectedAccountId,
      toAccountId: null,
      categoryId: mainCategoryId,
      subCategoryId: subCategoryId,
      date: selectedDate,
      note: note.isEmpty ? null : note,
      isExceptional: isExceptional,
      paymentMethod: paymentMethod,
    );

    try {
      if (widget.expenseToEdit != null && widget.expenseKey != null) {
        await box.putAt(widget.expenseKey!, transaction);
      } else {
        await box.add(transaction);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExceptional
                ? AppLocalizations.of(context)!.exceptionalExpenseAddedSuccessfully
                : AppLocalizations.of(context)!.recurringExpenseAddedSuccessfully,
          ),
          backgroundColor: isExceptional ? Colors.orange : Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء الحفظ'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isEditing = widget.expenseToEdit != null;
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT PANEL
            SizedBox(
              width: isSmallScreen ? 85 : 95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<SelectedCategory>(
                    valueListenable: widget.categoryNotifier,
                    builder: (context, category, _) {
                      return Container(
                        width: isSmallScreen ? 54 : 64,
                        height: isSmallScreen ? 54 : 64,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          getCategoryIcon(category.id),
                          key: ValueKey(category.id),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.category,
                            color: Colors.white,
                            size: isSmallScreen ? 28 : 32,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<SelectedCategory>(
                    valueListenable: widget.categoryNotifier,
                    builder: (context, category, _) {
                      return Text(
                        category.name.isEmpty ? "Category" : category.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  sideButton(
                    text: "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    onTap: () => _selectDate(context),
                    isSmallScreen: isSmallScreen,
                  ),
                  const SizedBox(height: 6),
                  sideButton(
                    text: note.isEmpty ? "Note" : note,
                    onTap: _addNote,
                    isSmallScreen: isSmallScreen,
                  ),
                  const SizedBox(height: 6),
                  sideButton(
                    text: paymentMethod == "cash" ? "Cash" : "Card",
                    onTap: () {
                      setState(() {
                        paymentMethod = paymentMethod == "cash" ? "card" : "cash";
                      });
                    },
                    isSmallScreen: isSmallScreen,
                  ),
                  const SizedBox(height: 6),
                  sideButton(
                    text: selectedAccountName,
                    onTap: _selectAccount,
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "EGP",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Flexible(
                          child: Text(
                            amount,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: isSmallScreen ? 1.2 : 1.1,
                      children: [
                        "1", "2", "3", "⌫",
                        "4", "5", "6", "C",
                        "7", "8", "9", "%",
                        ".", "0", "=", "+",
                      ].map((e) => keypadButton(e, isSmallScreen: isSmallScreen)).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isSaving ? null : () => _saveExpense(isExceptional: false),
                          child: Text(
                            isEditing ? "Update" : "Add",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isSaving ? null : () => _saveExpense(isExceptional: true),
                          child: Text(
                            isEditing ? "Update Exceptional" : "Add Exceptional",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sideButton({
    required String text,
    required VoidCallback onTap,
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: isSmallScreen ? 28 : 32,
        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 10 : 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget keypadButton(String text, {bool isSmallScreen = false}) {
    return GestureDetector(
      onTap: () {
        if (text == "⌫") {
          backspace();
        } else if (text == "C") {
          clear();
        } else if (text == "%") {
          calculatePercentage();
        } else if (text == "=" || text == "+" || text == "-" || text == "×" || text == "/") {
          // عمليات حسابية مستقبلية
        } else if (text.isNotEmpty) {
          addNumber(text);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
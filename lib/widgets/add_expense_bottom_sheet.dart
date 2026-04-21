// lib/widgets/add_expense_bottom_sheet.dart
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
import '../screens/accounts/add_account/add_account_screen.dart';

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

  // ✅ حساب الدين المؤقت الثابت
  static const String TEMP_DEBT_ACCOUNT_ID = 'temp_debt_account';
  static const String TEMP_DEBT_ACCOUNT_NAME = 'دين مؤقت';

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      amount = widget.expenseToEdit!.amount.toString();
      selectedDate = widget.expenseToEdit!.date;
      note = widget.expenseToEdit!.note ?? "";
      paymentMethod = widget.expenseToEdit!.paymentMethod;
      selectedAccountId = widget.expenseToEdit!.fromAccountId ?? "";
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
      // ✅ إزالة الـ cash الافتراضي - المستخدم يختار حساب بنفسه
      selectedAccountId = "";
      selectedAccountName = "اختر حساب";
    }
  }

  String _getAccountName(String accountId) {
    if (accountId.isEmpty) return "اختر حساب";
    if (accountId == TEMP_DEBT_ACCOUNT_ID) return TEMP_DEBT_ACCOUNT_NAME;

    final accountsBox = Hive.box<Account>('accounts');
    final account = accountsBox.get(accountId);
    return account?.name ?? accountId;
  }

  // ==========================================
  // ✅ دوال الحسابات القابلة للصرف
  // ==========================================

  /// هل يوجد حسابات قابلة للصرف (asset فقط، وليس دين مؤقت)
  bool _hasSpendableAccounts() {
    final accountsBox = Hive.box<Account>('accounts');
    return accountsBox.values.any((acc) =>
        acc.nature == 'asset' &&
        acc.type != 'investment' &&
        acc.type != 'lent' &&
        acc.id != TEMP_DEBT_ACCOUNT_ID);
  }

  /// الحصول على قائمة الحسابات القابلة للصرف
  List<Account> _getSpendableAccounts() {
    final accountsBox = Hive.box<Account>('accounts');
    return accountsBox.values.where((acc) =>
        acc.nature == 'asset' &&
        acc.type != 'investment' &&
        acc.type != 'lent' &&
        acc.id != TEMP_DEBT_ACCOUNT_ID).toList();
  }

  /// إنشاء حساب الدين المؤقت (مرة واحدة فقط عند الحاجة)
  Future<String> _ensureTempDebtAccount() async {
    final accountsBox = Hive.box<Account>('accounts');

    // ✅ هل الحساب موجود بالفعل؟
    var existing = accountsBox.get(TEMP_DEBT_ACCOUNT_ID);
    if (existing != null) return TEMP_DEBT_ACCOUNT_ID;

    // ✅ إنشاء حساب الدين المؤقت (أول استخدام فقط)
    final debtAccount = Account(
      id: TEMP_DEBT_ACCOUNT_ID,
      bookId: "personal",
      name: TEMP_DEBT_ACCOUNT_NAME,
      type: "debt",
      nature: "liability",
      currency: "EGP",
      createdAt: DateTime.now(),
    );

    await accountsBox.put(TEMP_DEBT_ACCOUNT_ID, debtAccount);
    return TEMP_DEBT_ACCOUNT_ID;
  }

  // ==========================================
  // ✅ Dialog: لا توجد حسابات
  // ==========================================

  Future<String?> _showNoAccountsDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text(
          "⚠️ لا توجد حسابات مالية بعد",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "ماذا تريد أن تفعل؟",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'create_account'),
            child: const Text("➕ إنشاء حساب", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'temp_debt'),
            child: const Text("📝 تسجيل المصروف كدين مؤقت", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ✅ Dialog: الرصيد غير كافٍ
  // ==========================================

  Future<String?> _showInsufficientBalanceDialog(double neededAmount, double currentBalance) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              "⚠️ الرصيد غير كافٍ",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "الرصيد الحالي: ${currentBalance.toStringAsFixed(0)} EGP",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "المبلغ المطلوب: ${neededAmount.toStringAsFixed(0)} EGP",
              style: const TextStyle(color: Colors.orange),
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
            onPressed: () => Navigator.pop(context, 'temp_debt'),
            child: const Text("📝 تسجيل المصروف كدين مؤقت", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ✅ حفظ كدين مؤقت
  // ==========================================

  Future<void> _saveAsTempDebt(double value, bool isExceptional) async {
    // ✅ إنشاء حساب الدين المؤقت (مرة واحدة فقط)
    final debtAccountId = await _ensureTempDebtAccount();

    setState(() {
      selectedAccountId = debtAccountId;
      selectedAccountName = TEMP_DEBT_ACCOUNT_NAME;
    });

    await _saveExpenseDirectly(value, isExceptional);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExceptional
                ? "📝 تم تسجيل المصروف الاستثنائي كدين مؤقت"
                : "📝 تم تسجيل المصروف كدين مؤقت",
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  // ==========================================
  // ✅ حفظ المصروف مباشرة
  // ==========================================

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

  // ==========================================
  // ✅ إضافة رصيد (مؤقت - تفتح AddAccountScreen)
  // ==========================================

  Future<void> _addBalanceToAccount(String accountId, double shortage) async {
    // مؤقتاً نفتح AddAccountScreen
    // لاحقاً سيتم استبداله بشاشة إضافة رصيد منفصلة
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("➕ افتح شاشة الحسابات ثم عدّل رصيد الحساب الحالي"),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAccountScreen()));
    }
  }

  // ==========================================
  // ✅ حفظ المصروف (المنطق الرئيسي)
  // ==========================================

  Future<void> _saveExpense({required bool isExceptional}) async {
    if (_isSaving) return;

    final value = double.tryParse(amount) ?? 0;
    if (value == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterValidAmount)),
      );
      return;
    }

    // ✅ 1. التحقق من وجود حسابات قابلة للصرف
    if (!_hasSpendableAccounts() && widget.expenseToEdit == null) {
      final action = await _showNoAccountsDialog();

      if (action == 'create_account') {
        if (mounted) {
          Navigator.pop(context);

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddAccountScreen(),
            ),
          );

          if (mounted) {
            showAddExpenseSheet(context, widget.categoryNotifier);
          }
        }
        return;
      }

      if (action == 'temp_debt') {
        await _saveAsTempDebt(value, isExceptional);
        return;
      }

      return;
    }

    // ✅ 2. التأكد من اختيار حساب
    if (selectedAccountId.isEmpty && widget.expenseToEdit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ الرجاء اختيار حساب أولاً"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // ✅ 3. التحقق من الرصيد (للمصروفات الجديدة فقط)
    if (widget.expenseToEdit == null && selectedAccountId.isNotEmpty) {
      final currentBalance = BalanceService().getBalance(selectedAccountId);

      if (currentBalance < value) {
        final action = await _showInsufficientBalanceDialog(value, currentBalance);

        if (action == 'add_balance') {
          await _addBalanceToAccount(selectedAccountId, value - currentBalance);
          return;
        }

        if (action == 'temp_debt') {
          await _saveAsTempDebt(value, isExceptional);
          return;
        }

        if (action == 'cancel') {
          return;
        }
      }
    }

    // ✅ 4. حفظ المصروف عادي
    await _saveExpenseDirectly(value, isExceptional);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isExceptional ? "✅ تم تسجيل المصروف الاستثنائي" : "✅ تم تسجيل المصروف"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  // ==========================================
  // ✅ اختيار الحساب (يعرض فقط الحسابات القابلة للصرف)
  // ==========================================

  void _selectAccount() {
    final spendableAccounts = _getSpendableAccounts();

    // ✅ لو مفيش حسابات، نفتح الـ Dialog مباشرة
    if (spendableAccounts.isEmpty) {
      _showNoAccountsDialog();
      return;
    }

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

  // ==========================================
  // ✅ دوال مساعدة (موجودة بالفعل)
  // ==========================================

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

  Color _getAccountColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      case 'debt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.attach_money;
      case 'bank':
        return Icons.account_balance;
      case 'debt':
        return Icons.receipt_long;
      default:
        return Icons.account_balance_wallet;
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

  // ==========================================
  // ✅ build
  // ==========================================

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
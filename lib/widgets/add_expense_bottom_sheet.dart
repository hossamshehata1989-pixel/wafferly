import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../utils/category_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../config/category_config.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_helper.dart';

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
  Expense? expenseToEdit,
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
  final Expense? expenseToEdit;
  final int? expenseKey;

  const AddExpenseBottomSheet({
    super.key,
    required this.categoryNotifier,
    this.expenseToEdit,
    this.expenseKey,
  });

  @override
  State<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState
    extends State<AddExpenseBottomSheet> {
  late String amount;
  late DateTime selectedDate;
  late String note;
  late String paymentMethod;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      amount = widget.expenseToEdit!.amount.toString();
      selectedDate = widget.expenseToEdit!.date;
      note = widget.expenseToEdit!.note ?? "";
      paymentMethod = widget.expenseToEdit!.paymentMethod;
      
      widget.categoryNotifier.value = SelectedCategory(
        id: widget.expenseToEdit!.subCategoryId ?? widget.expenseToEdit!.mainCategoryId,
        name: widget.expenseToEdit!.subCategoryId ?? widget.expenseToEdit!.mainCategoryId,
      );
    } else {
      amount = "0";
      selectedDate = DateTime.now();
      note = "";
      paymentMethod = "cash";
    }
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

  // ✅ دالة لمعرفة الفئة الرئيسية من الفئة الفرعية
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



  // ✅ دالة لمعرفة إذا كانت الفئة فرعية أم رئيسية
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

  Future<void> _saveExpense({required bool isExceptional}) async {
    if (_isSaving) return;
    
    final value = double.tryParse(amount) ?? 0;
    if (value == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(AppLocalizations.of(context)!.pleaseEnterValidAmount),
    backgroundColor: Colors.orange,
    duration: const Duration(seconds: 2),
  ),
);
      return;
    }

    setState(() => _isSaving = true);

    final box = Hive.box<Expense>('expenses');
    
    final selected = widget.categoryNotifier.value;
    final isSub = _isSubCategory(selected.id);
    
    final expense = Expense(
      id: widget.expenseToEdit?.id,
      amount: value,
      mainCategoryId: _getMainCategoryId(selected.id),
    
      subCategoryId: isSub ? selected.id : null,
      date: selectedDate,
      isExceptional: isExceptional,
      note: note.isEmpty ? null : note,
      paymentMethod: paymentMethod,
    );

    try {
      if (widget.expenseToEdit != null && widget.expenseKey != null) {
        await box.put(widget.expenseKey!, expense);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(AppLocalizations.of(context)!.expenseUpdatedSuccessfully),
    backgroundColor: Colors.orange,
    duration: const Duration(seconds: 2),
  ),
);
      } else {
        await box.add(expense);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      isExceptional 
        ? AppLocalizations.of(context)!.exceptionalExpenseAddedSuccessfully
        : AppLocalizations.of(context)!.recurringExpenseAddedSuccessfully,
    ),
    backgroundColor: isExceptional ? Colors.orange : Colors.green,
    duration: const Duration(seconds: 2),
  ),
);
      }
      
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
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
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
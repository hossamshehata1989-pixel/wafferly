import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../utils/category_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class SelectedCategory {
  final String id;
  final String name;

  SelectedCategory({
    required this.id,
    required this.name,
  });
}

/// 🔥 FIX: remove persistent controller (كان سبب التهنيج)
void showAddExpenseSheet(
  BuildContext context,
  ValueNotifier<SelectedCategory> categoryNotifier,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return FractionallySizedBox(
        heightFactor: 0.4,
        child: AddExpenseBottomSheet(
          categoryNotifier: categoryNotifier,
        ),
      );
    },
  );
}

class AddExpenseBottomSheet extends StatefulWidget {
  final ValueNotifier<SelectedCategory> categoryNotifier;

  const AddExpenseBottomSheet({
    super.key,
    required this.categoryNotifier,
  });

  @override
  State<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState
    extends State<AddExpenseBottomSheet> {

  String amount = "0";

  DateTime selectedDate = DateTime.now();
  String note = "";
  String paymentMethod = "Cash";

  String activeField = "";

  bool isExceptional = false; // 🔥 الجديد

  /// =========================
  /// 💾 SAVE
  /// =========================
  void saveExpense() {
    final value = double.tryParse(amount) ?? 0;
    if (value == 0) return;

    final box = Hive.box<Expense>('expenses');

    final newExpense = Expense(
      amount: value,
      category: widget.categoryNotifier.value.name,
      date: selectedDate,
      isExceptional: isExceptional,
    );

    box.add(newExpense);

    Navigator.pop(context);
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

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        activeField = "date";
      });
    }
  }

  void addNote() {
    final controller = TextEditingController(text: note);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Note"),
          content: TextField(
            controller: controller,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  note = controller.text;
                  if (note.isNotEmpty) {
                    activeField = "note";
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void pickPayment() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              title: const Text("Cash"),
              onTap: () {
                setState(() {
                  paymentMethod = "Cash";
                  activeField = "payment";
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              title: const Text("Card"),
              onTap: () {
                setState(() {
                  paymentMethod = "Card";
                  activeField = "payment";
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              title: const Text("Wallet"),
              onTap: () {
                setState(() {
                  paymentMethod = "Wallet";
                  activeField = "payment";
                });
                Navigator.pop(context);
              },
            ),

          ],
        );
      },
    );
  }

  String getPaymentIcon() {
    if (paymentMethod == "Card") {
      return "assets/icons/ui/card.svg";
    } else {
      return "assets/icons/ui/wallet.svg";
    }
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(22)),
        ),

        child: Row(
          children: [

            /// LEFT
            SizedBox(
              width: 75,
              child: Column(
                children: [

                  ValueListenableBuilder<SelectedCategory>(
                    valueListenable: widget.categoryNotifier,
                    builder: (context, category, _) {
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.cardSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          getCategoryIcon(category.id),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  InkWell(
                    onTap: pickDate,
                    child: sideButton(
                      text: "${selectedDate.day}/${selectedDate.month}",
                      iconPath: "assets/icons/ui/calendar.svg",
                      isActive: activeField == "date",
                    ),
                  ),

                  const SizedBox(height: 6),

                  InkWell(
                    onTap: addNote,
                    child: sideButton(
                      text: note.isEmpty ? "Note" : "Added",
                      iconPath: "assets/icons/ui/note.svg",
                      isActive: activeField == "note",
                    ),
                  ),

                  const SizedBox(height: 6),

                  InkWell(
                    onTap: pickPayment,
                    child: sideButton(
                      text: paymentMethod,
                      iconPath: getPaymentIcon(),
                      isActive: activeField == "payment",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            /// RIGHT
            Expanded(
              child: Column(
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("EGP",
                            style: TextStyle(color: Colors.white70)),
                        Text(amount,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// 🔢 KEYPAD
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    childAspectRatio: 1.8,
                    children: [
                      ...[
                        "1","2","3","⌫",
                        "4","5","6","C",
                        "7","8","9","",
                        ".","0","","",
                      ].map((e) => keypadButton(e)),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// 🔥 BUTTONS
                  Row(
                    children: [

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          onPressed: () {
                            isExceptional = false;
                            saveExpense();
                          },
                          child: const Text("Add"),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            isExceptional = true;
                            saveExpense();
                          },
                          child: const Text("Add Exceptional"),
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
    required String iconPath,
    required bool isActive,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacity(0.2)
            : AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          SvgPicture.asset(
            iconPath,
            width: 16,
            height: 16,
            color: Colors.white70,
          ),

          const SizedBox(width: 6),

          Text(text,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget keypadButton(String text) {
    return GestureDetector(
      onTap: () {
        if (text == "⌫") backspace();
        else if (text == "C") clear();
        else if (text.isNotEmpty) addNumber(text);
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              )),
        ),
      ),
    );
  }
}
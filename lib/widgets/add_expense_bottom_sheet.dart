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

PersistentBottomSheetController? _controller;

void showAddExpenseSheet(
  BuildContext context,
  ValueNotifier<SelectedCategory> categoryNotifier,
) {

  if (_controller != null) return;

  _controller = Scaffold.of(context).showBottomSheet(

    (context) => FractionallySizedBox(
      heightFactor: 0.4, // 👈 يتحكم في الارتفاع
      child: AddExpenseBottomSheet(
        categoryNotifier: categoryNotifier,

      ),
    ),

  );

  _controller!.closed.then((_) {
    _controller = null;
  });

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

            /// LEFT PANEL
            SizedBox(
              width: 75,

              child: Column(

                children: [

                  /// CATEGORY ICON

                  ValueListenableBuilder<SelectedCategory>(

                    valueListenable: widget.categoryNotifier,

                    builder: (context, category, _) {

                      return Container(

                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(1),

                        decoration: BoxDecoration(
                          color: AppColors.cardSecondary,
                          shape: BoxShape.circle,
                        ),

                        child: SvgPicture.asset(
                          getCategoryIcon(category.id),
                          key: ValueKey(category.id),
                        ),

                      );

                    },

                  ),

                  const SizedBox(height: 3),

                  const Text(
                    "Category",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 1),

                  sideButton("Date"),
                  const SizedBox(height: 6),

                  sideButton("Note"),
                  const SizedBox(height: 6),

                  sideButton("Cash"),

                ],
              ),
            ),

            const SizedBox(width: 0),

            /// RIGHT PANEL
            Expanded(

              child: Column(

                children: [

                  /// AMOUNT DISPLAY

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

                        const Text(
                          "EGP",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        Text(
                          amount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// KEYPAD

                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GridView.count(

                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),

                      crossAxisCount: 4,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.853, // 👈 ده السحر 🔥

                      children: [

                        ...[
                          "1","2","3","⌫",
                          "4","5","6","C",
                          "7","8","9","×",
                          ".","0","=","+",
                        ].map((e) => keypadButton(e)),

                      ],

                    ),
                  ),

                  const SizedBox(height: 6),

                  /// SAVE BUTTON

                  SizedBox(

                    width: double.infinity,
                    height: 40,

                    child: ElevatedButton(

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),

                      onPressed: () {

                        final value = double.tryParse(amount) ?? 0;

                        // ❌ منع حفظ قيمة صفر
                        if (value == 0) return;

                        final box = Hive.box<Expense>('expenses');

                        final newExpense = Expense(

                          // -------------------------------------------------
                          // 🏷 Title (مؤقت لحد ما نضيف input)
                          // -------------------------------------------------
                          title: "Expense",

                          // -------------------------------------------------
                          // 💰 Amount من الكيباد
                          // -------------------------------------------------
                          amount: double.tryParse(amount) ?? 0,

                          // -------------------------------------------------
                          // 📂 Category
                          // -------------------------------------------------
                          category: widget.categoryNotifier.value.name,

                          // -------------------------------------------------
                          // 📅 Date
                          // -------------------------------------------------
                          date: DateTime.now(),
                        );

                          // ---------------------------------------------------
                          // 🔥 Save to Hive
                          // ---------------------------------------------------
                        box.add(newExpense);

                          // ---------------------------------------------------
                          // ❌ Close BottomSheet
                          // ---------------------------------------------------
                        Navigator.pop(context);
                      },

                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                    ),

                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sideButton(String text) {      // زر جانبي بسيط (التاريخ، الملاحظة، طريقة الدفع، ...)

    return Container(

      width: double.infinity,
      height: 40,

      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(8),
      ),

      child: Center(           // نص الزر
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),

    );

  }

  Widget keypadButton(String text) {

    return GestureDetector(

      onTap: () {

        if (text == "⌫") {
          backspace();
        }

        else if (text == "C") {
          clear();
        }

        else if (text.isNotEmpty) {
          addNumber(text);
        }

      },

      child: Container(
        height: 50,   // ← غير الرقم ده

        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius:
              BorderRadius.circular(12),
        ),

        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
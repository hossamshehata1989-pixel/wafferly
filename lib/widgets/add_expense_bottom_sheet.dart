import 'package:flutter/material.dart';

/// ===============================================================
/// 🔹 دالة فتح شاشة إضافة مصروف (Bottom Sheet)
/// ===============================================================
void showAddExpenseSheet(BuildContext context, String categoryName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>  SizedBox(
      height: 295, // 🔹 ارتفاع ثابت
      child: AddExpenseBottomSheet(
        categoryName: categoryName,
      ),
    ),
  );
}

/// ===============================================================
/// 🔹 StatefulWidget
/// ===============================================================
class AddExpenseBottomSheet extends StatefulWidget {
  final String categoryName;

  const AddExpenseBottomSheet({
    super.key,
    required this.categoryName,
  });

  @override
  State<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

/// ===============================================================
/// 🔹 State
/// ===============================================================
class _AddExpenseBottomSheetState
    extends State<AddExpenseBottomSheet> {

  String amount = "0";

  /// إضافة رقم
  void addNumber(String n) {
    setState(() {
      if (amount == "0") {
        amount = n;
      } else {
        amount += n;
      }
    });
  }

  /// مسح الكل
  void clear() => setState(() => amount = "0");

  /// حذف آخر رقم
  void backspace() {
    setState(() {
      if (amount.length > 1) {
        amount = amount.substring(0, amount.length - 1);
      } else {
        amount = "0";
      }
    });
  }

  /// ===========================================================
  /// 🔹 UI
  /// ===========================================================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: const BoxDecoration(
          color: Color(0xFF1B2A6B),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===================================================
            /// 🔵 LEFT SIDE
            /// ===================================================
            Expanded(
              flex: 4,
              child: Column(
                children: [

                  /// 🔹 Amount Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),

                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1B4C),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// 🔹 Keypad
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: [

                        ...[
                          "⌫","1","2","3","/",
                          "C","4","5","6","×",
                          "%","7","8","9","-",
                          "",".","0","=","+",
                        ].map((e) => keypadButton(e)),

                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            /// ===================================================
            /// 🟡 RIGHT SIDE
            /// ===================================================
            Expanded(
              flex: 1,
              child: Column(
                children: [

                  /// 🔹 Category Card
                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: const Color(0xFF243A8F),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: Column(
                      children: [

                        const Icon(
                          Icons.local_gas_station,
                          size: 30,
                          color: Color(0xFF4FD1FF),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          widget.categoryName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// 🔹 Today Button
                  sideButton(
                    icon: Icons.calendar_today,
                    label: "Today",
                  ),

                  const SizedBox(height: 6),

                  /// 🔹 Notes Button
                  sideButton(
                    icon: Icons.note,
                    label: "Notes",
                  ),

                  const SizedBox(height: 6),

                  /// 🔹 Save Button
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 20),

                    decoration: BoxDecoration(
                      color: const Color(0xFF3A7BFF),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: const Center(
                      child: Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  /// ===========================================================
  /// 🔹 Keypad Button
  /// ===========================================================
  Widget keypadButton(String text) {
    return GestureDetector(
      onTap: () {

        if (text == "⌫") {
          backspace();
        } else if (text == "C") {
          clear();
        } else if (text.isNotEmpty) {
          addNumber(text);
        }

      },

      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF243A8F),
          borderRadius:
              BorderRadius.circular(12),
        ),

        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// ===========================================================
  /// 🔹 Side Button
  /// ===========================================================
  Widget sideButton({
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 14),

      decoration: BoxDecoration(
        color: const Color(0xFF243A8F),
        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          Icon(
            icon,
            size: 18,
            color: const Color(0xFF4FD1FF),
          ),

          const SizedBox(width: 6),

          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
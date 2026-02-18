import 'package:flutter/material.dart';

/// ===============================================================
/// 🔹 دالة فتح شاشة إضافة مصروف (Bottom Sheet)
/// ===============================================================
/// تستقبل:
/// - context : علشان نعرف نفتح الـ BottomSheet
/// - categoryName : اسم الفئة اللي المستخدم اختارها
/// ===============================================================
void showAddExpenseSheet(BuildContext context, String categoryName) {
  showModalBottomSheet(
    context: context,

    /// يسمح للـ BottomSheet ياخد مساحة كبيرة من الشاشة
    isScrollControlled: true,

    /// نخلي الخلفية شفافة علشان الحواف الدائرية تبان
    backgroundColor: Colors.transparent,

    /// بنستخدم DraggableScrollableSheet علشان المستخدم يقدر
    /// يسحب الشاشة لفوق وتحت
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6, // يبدأ بـ 60% من الشاشة
      minChildSize: 0.45,    // أقل حاجة 45%
      maxChildSize: 0.9,     // أقصى حاجة 90%
      expand: false,
      builder: (_, controller) => AddExpenseBottomSheet(
        categoryName: categoryName,
        scrollController: controller,
      ),
    ),
  );
}

/// ===============================================================
/// 🔹 StatefulWidget علشان المبلغ بيتغير مع الضغط على الأزرار
/// ===============================================================
class AddExpenseBottomSheet extends StatefulWidget {

  /// اسم الفئة المختارة
  final String categoryName;

  /// الكنترولر المسؤول عن سحب الشاشة
  final ScrollController scrollController;

  const AddExpenseBottomSheet({
    super.key,
    required this.categoryName,
    required this.scrollController,
  });

  @override
  State<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

/// ===============================================================
/// 🔹 الـ State اللي فيه كل المنطق
/// ===============================================================
class _AddExpenseBottomSheetState
    extends State<AddExpenseBottomSheet> {

  /// المبلغ اللي المستخدم بيكتبه
  /// استخدمنا String علشان نقدر نضيف أرقام وعلامات رياضية
  String amount = "0";

  /// ===========================================================
  /// 🔹 دالة إضافة رقم أو رمز
  /// ===========================================================
  void addNumber(String n) {
    setState(() {

      /// لو المبلغ الحالي صفر → استبدله
      if (amount == "0") {
        amount = n;
      } else {

        /// غير كده → ضيف الرمز في الآخر
        amount += n;
      }
    });
  }

  /// ===========================================================
  /// 🔹 مسح كل المبلغ
  /// ===========================================================
  void clear() => setState(() => amount = "0");

  /// ===========================================================
  /// 🔹 حذف آخر حرف (زرار ⌫)
  /// ===========================================================
  void backspace() {
    setState(() {

      /// لو فيه أكتر من حرف → احذف آخر حرف
      if (amount.length > 1) {
        amount =
            amount.substring(0, amount.length - 1);
      } else {

        /// لو حرف واحد بس → رجعه صفر
        amount = "0";
      }
    });
  }

  /// ===========================================================
  /// 🔹 بناء الواجهة
  /// ===========================================================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),

        /// شكل الخلفية + الحواف الدائرية
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),

        /// Row علشان نقسم الشاشة عمودين
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===================================================
            /// 🔵 الجزء الشمال (المبلغ + الكيباد)
            /// ===================================================
            Expanded(
              flex: 4, // ياخد 4/5 العرض تقريبًا
              child: Column(
                children: [

                  /// 🔹 شريط عرض المبلغ
                  Container(                                    // تصميم الشريط
                    padding: const EdgeInsets.symmetric(           
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C44),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    /// صف فيه العملة شمال والمبلغ يمين
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "EGP",
                          style: TextStyle(
                              color: Colors.white70),
                        ),
                        Text(
                          amount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 🔹 الكيباد
                  /// بنجبره يبقى LTR علشان الأرقام متتعكسش
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5, // 5 أعمدة
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
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
            /// 🟡 الجزء اليمين (الفئة + الأزرار)
            /// ===================================================
            Expanded(
              flex: 1, // ياخد 1/5 العرض
              child: Column(
                children: [

                  /// 🔹 كارت الفئة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5D7),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Column(          // صف أيقونة الفئة واسمها
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_gas_station,       // هيتغير لاحقا ويتربط
                          size: 30,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.categoryName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// 🔹 زرار Today
                  sideButton(
                      icon: Icons.calendar_today,
                      label: "Today"),

                  const SizedBox(height: 4),

                  /// 🔹 زرار Notes
                  sideButton(
                      icon: Icons.note,
                      label: "Notes"),

                  const SizedBox(height: 4),

                  /// 🔹 زرار Save
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C4A7A),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        "Save",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
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
  /// 🔹 تصميم زرار الكيباد
  /// ===========================================================
  Widget keypadButton(String text) {
    return GestureDetector(
      onTap: () {

        /// لو زرار حذف
        if (text == "⌫") {
          backspace();
        } else {

          /// غير كده ضيف الرمز
          addNumber(text);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// ===========================================================
  /// 🔹 زرار جانبي (Today / Notes)
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
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

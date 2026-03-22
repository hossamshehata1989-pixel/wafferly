import 'package:flutter/material.dart';

/// Widgets
import '../widgets/main_categories_section.dart';
import '../widgets/sub_categories_section.dart';
import '../widgets/add_expense_bottom_sheet.dart';

/// 🔥 Expenses List
import 'expenses_list.dart';

/// Localization
import '../l10n/app_localizations.dart';

/// Theme
import '../theme/app_colors.dart';
import '../data/categories_data.dart';


class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {

  int selectedMainIndex = -1;

  /// Tabs
  int tabIndex = 0;

  /// notifier للفئة المختارة
  final ValueNotifier<SelectedCategory> selectedCategory =
      ValueNotifier(
    SelectedCategory(
      id: "",
      name: "",
    ),
  );

  void switchTab(int index) {

    /// اغلاق الـ BottomSheet لو مفتوح
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    setState(() {
      tabIndex = index;
      selectedMainIndex = -1;
    });

  }

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Scaffold(

      appBar: AppBar(
        toolbarHeight: 35,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: Container(

          height: 35,

          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),

          child: Row(

            children: [

              /// EXPENSES
              Expanded(
                child: GestureDetector(

                  onTap: () => switchTab(0),

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),

                    decoration: BoxDecoration(
                      color: tabIndex == 0
                          ? AppColors.card
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Center(
                      child: Text(
                        t.expenses,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tabIndex == 0
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),

                  ),

                ),
              ),

              /// INCOME
              Expanded(
                child: GestureDetector(

                  onTap: () => switchTab(1),

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),

                    decoration: BoxDecoration(
                      color: tabIndex == 1
                          ? AppColors.card
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Center(
                      child: Text(
                        t.income,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tabIndex == 1
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),

                  ),

                ),
              ),

            ],

          ),

        ),

      ),

      body: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: tabIndex == 0
            ? expensesBody(t)
            : incomeBody(),
      ),
    );
  }

  /// ===============================
  /// EXPENSES PAGE
  /// ===============================
  Widget expensesBody(AppLocalizations t) {

    return SingleChildScrollView(

      child: Column(

        children: [

          const SizedBox(height: 10),

          MainCategoriesSection(
            selectedIndex: selectedMainIndex,
            selectedCategory: selectedCategory,
            onSelect: (i) {

              setState(() {
                selectedMainIndex = i;
              });

            },
          ),

          const SizedBox(height: 10),

          if (selectedMainIndex >= 0 &&
              selectedMainIndex < mainCategories.length)
            SubCategoriesSection(
              key: ValueKey(selectedMainIndex),
              mainCategoryIndex: selectedMainIndex,
              selectedCategory: selectedCategory,
            )

          else

            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                t.chooseCategoryFirst,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // =====================================================
          // 💸 EXPENSES LIST (LIVE FROM HIVE)
          // =====================================================

          SizedBox(
            height: 300,
            child: const ExpensesList(),
          ),

          const SizedBox(height: 20),

        ],

      ),

    );

  }

  /// ===============================
  /// INCOME PAGE
  /// ===============================
  Widget incomeBody() {

    final incomeCategories = [

      {"name": "راتب", "icon": Icons.work},
      {"name": "حوافز / مكافئات", "icon": Icons.card_giftcard},
      {"name": "يومية", "icon": Icons.today},
      {"name": "استثمار", "icon": Icons.trending_up},
      {"name": "بيع", "icon": Icons.sell},
      {"name": "فريلانسر", "icon": Icons.laptop},
      {"name": "دخل إضافي", "icon": Icons.add_circle},
      {"name": "هدايا", "icon": Icons.redeem},
      {"name": "أخرى", "icon": Icons.category},

    ];

    return GridView.builder(

      padding: const EdgeInsets.all(16),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),

      itemCount: incomeCategories.length,

      itemBuilder: (context, index) {

        final item = incomeCategories[index];

        return GestureDetector(

          onTap: () {

            selectedCategory.value = SelectedCategory(
              id: "income_$index",
              name: item["name"] as String,
            );

            showAddExpenseSheet(
              context,
              selectedCategory,
            );

          },

          child: Container(

            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardSecondary),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Icon(
                  item["icon"] as IconData,
                  size: 30,
                  color: Colors.white,
                ),

                const SizedBox(height: 10),

                Text(
                  item["name"] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

              ],
            ),

          ),

        );

      },

    );

  }

}
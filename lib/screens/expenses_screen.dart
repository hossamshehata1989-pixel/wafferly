import 'package:flutter/material.dart';
import '../widgets/main_categories_section.dart';
import '../widgets/sub_categories_section.dart';
import '../l10n/app_localizations.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int selectedMainIndex = -1; // -1 يعني مفيش اختيار

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          t.expenses,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// 🔷 Main Categories
            MainCategoriesSection(
              selectedIndex: selectedMainIndex,
              onSelect: (i) {
                setState(() {
                  selectedMainIndex = i;
                });
              },
            ),

            const SizedBox(height: 10),

            /// 🔷 Sub Categories
            if (selectedMainIndex != -1)
              SubCategoriesSection(
                key: ValueKey(selectedMainIndex), // مهم لإعادة البناء
                mainCategoryIndex: selectedMainIndex,
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
          ],
        ),
      ),
    );
  }
}

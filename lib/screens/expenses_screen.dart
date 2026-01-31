import 'package:flutter/material.dart';
import '../widgets/main_categories_section.dart';
import '../widgets/sub_categories_section.dart';
import '../l10n/app_localizations.dart'; // 👈 إضافة

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int selectedMainIndex = -1;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // 👈 اختصار للترجمة

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        centerTitle: true,
        elevation: 0,
        title: Text(
          t.expenses, // 👈 مترجمة بدل "Expenses"
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            MainCategoriesSection(
              selectedIndex: selectedMainIndex,
              onSelect: (i) {
                setState(() {
                  selectedMainIndex = i;
                });
              },
            ),

            const SizedBox(height: 18),

            SubCategoriesSection(
              mainCategoryIndex: selectedMainIndex,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

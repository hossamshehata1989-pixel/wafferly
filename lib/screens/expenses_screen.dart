import 'package:flutter/material.dart';
import '../widgets/main_categories_section.dart';
import '../widgets/sub_categories_section.dart';
import '../widgets/add_expense_bottom_sheet.dart';
import '../l10n/app_localizations.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int selectedMainIndex = -1;
  final ValueNotifier<SelectedCategory> selectedCategory = ValueNotifier(
    SelectedCategory(id: "", name: "")
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.expenses), 
        backgroundColor: const Color(0xFF0A0A0A),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MainCategoriesSection(
                    selectedIndex: selectedMainIndex,
                    selectedCategory: selectedCategory,
                    onSelect: (index) => setState(() => selectedMainIndex = index),
                  ),
                  const SizedBox(height: 10),
                  if (selectedMainIndex >= 0)
                    SubCategoriesSection(
                      mainCategoryIndex: selectedMainIndex,
                      selectedCategory: selectedCategory,
                    ),
                  // إضافة مساحة إضافية أسفل المحتوى
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
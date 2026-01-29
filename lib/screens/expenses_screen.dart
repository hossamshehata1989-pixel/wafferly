import 'package:flutter/material.dart';
import '../widgets/main_categories_section.dart';
import '../widgets/sub_categories_section.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedMainIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text("Expenses"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Expenses"),
            Tab(text: "Incomes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            children: [
              const SizedBox(height: 12),
              MainCategoriesSection(
                selectedIndex: selectedMainIndex,
                onSelect: (i) => setState(() => selectedMainIndex = i),
              ),
              const SizedBox(height: 20),
              SubCategoriesSection(mainIndex: selectedMainIndex),
              const SizedBox(height: 40),
            ],
          ),
          const Center(child: Text("Incomes Screen (Later)")),
        ],
      ),
    );
  }
}

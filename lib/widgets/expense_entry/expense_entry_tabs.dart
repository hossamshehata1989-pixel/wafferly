// lib/widgets/expense_entry/expenses_income_tabs.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';

class ExpenseEntryTabs extends StatelessWidget {
  final dynamic controller; // TransactionEntryController

  const ExpenseEntryTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    // Tabs height responsive: 44px مرجع → 33px على iPhone SE
    final isSmallScreen = metrics.width < 360;

    final double tabHeight = isSmallScreen ? metrics.h(38) : metrics.h(45);
    final double fontSize = metrics.text(14);
    final double borderRadius = 24;

    final tabs = ['Expenses', 'Income', 'Transfer'];
    final selectedIndex = _selectedIndex(controller);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: metrics.spacing(16)),
      height: tabHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // Animated selector
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: _alignment(selectedIndex),
            child: FractionallySizedBox(
              widthFactor: 1 / tabs.length,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
          ),

          // Tab labels
          Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTap(controller, index),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Alignment _alignment(int index) {
    switch (index) {
      case 0:
        return const Alignment(-1, 0);
      case 1:
        return const Alignment(0, 0);
      case 2:
        return const Alignment(1, 0);
      default:
        return const Alignment(-1, 0);
    }
  }

  int _selectedIndex(dynamic controller) {
    // يعتمد على TransactionType في الـ controller
    final type = controller.selectedTransactionType as String;
    if (type == 'income') return 1;
    if (type == 'transfer') return 2;
    return 0;
  }

  void _onTap(dynamic controller, int index) {
    switch (index) {
      case 0:
        controller.setTransactionType('expense');
        break;
      case 1:
        controller.setTransactionType('income');
        break;
      case 2:
        controller.setTransactionType('transfer');
        break;
    }
  }
}

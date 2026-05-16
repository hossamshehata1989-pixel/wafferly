// lib/widgets/expense_entry/expense_entry_tabs.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../constants/transaction_constants.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ExpenseEntryTabs extends StatelessWidget {
  final TransactionEntryController controller;

  const ExpenseEntryTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(t.expenses, TransactionType.expense),
          _buildTab(t.income, TransactionType.income),
          _buildTab(t.transfer, TransactionType.transfer),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String transactionType) {
    final isSelected = controller.selectedTransactionType == transactionType;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.setTransactionType(transactionType),
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white24,
              highlightColor: Colors.transparent,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// lib/screens/expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/transaction_entry_controller.dart';
import '../widgets/expense_entry/expense_entry_tabs.dart';
import '../widgets/expense_entry/main_categories_grid.dart';
import '../widgets/expense_entry/sub_categories_grid.dart';
import '../widgets/expense_entry/amount_input_panel.dart';
import '../widgets/expense_entry/transfer_form.dart';
import '../l10n/app_localizations.dart';
import '../constants/transaction_constants.dart';
import '../models/transaction.dart';
import '../theme/responsive_metrics.dart';
import '../widgets/expense_entry/recent_transactions_preview.dart';

class ExpensesScreen extends StatelessWidget {
  final String initialType;
  final Transaction? transactionToEdit;

  const ExpensesScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.transactionToEdit,
  });

  void _showAccountPicker(
    BuildContext context,
    TransactionEntryController controller,
  ) {
    final accounts = controller.availableAccounts;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: ListView(
            children: accounts.map((account) {
              return ListTile(
                title: Text(account.name),
                onTap: () {
                  controller.selectAccount(account.id, account.name);

                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    final isCompactScreen = metrics.width < 360 || metrics.height < 700;

    return ChangeNotifierProvider(
      create: (_) {
        final controller = TransactionEntryController();
        if (transactionToEdit != null) {
          controller.loadTransaction(transactionToEdit!);
        } else {
          controller.setTransactionType(initialType);
        }
        return controller;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          // AppBar responsive: 56px مرجع → 42px على iPhone SE
          preferredSize: Size.fromHeight(metrics.h(45)),
          child: AppBar(
            title: Text(
              transactionToEdit != null
                  ? 'Edit Transaction'
                  : initialType == TransactionType.income
                  ? AppLocalizations.of(context)!.income
                  : (initialType == TransactionType.transfer
                        ? AppLocalizations.of(context)!.transfer
                        : AppLocalizations.of(context)!.expenses),
              style: TextStyle(fontSize: metrics.text(18)),
            ),
            backgroundColor: const Color(0xFF0A0A0A),
            toolbarHeight: metrics.h(56),
          ),
        ),
        body: Consumer<TransactionEntryController>(
          builder: (context, controller, _) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardOpen = keyboardHeight > 0;
            final isTransfer =
                controller.selectedTransactionType == TransactionType.transfer;
            final isExpense = controller.isExpense;

            return SafeArea(
              child: Column(
                children: [
                  // TABS
                  if (!controller.isEditing) ...[
                    ExpenseEntryTabs(controller: controller),
                    SizedBox(height: metrics.h(3)),
                  ] else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: metrics.h(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.white70,
                            size: metrics.size(18),
                          ),
                          SizedBox(width: metrics.spacing(8)),
                          Text(
                            'Edit Transaction',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: metrics.text(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // TRANSFER
                  if (isTransfer)
                    Expanded(child: TransferForm(controller: controller))
                  else
                    Expanded(
                      child: _buildExpenseIncomeContent(
                        context: context,
                        controller: controller,
                        isKeyboardOpen: isKeyboardOpen,
                        isExpense: isExpense,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseIncomeContent({
    required BuildContext context,
    required TransactionEntryController controller,
    required bool isKeyboardOpen,
    required bool isExpense,
  }) {
    final metrics = ResponsiveMetrics.of(context);

    final isCompactScreen = metrics.width < 360 || metrics.height < 700;

    return Column(
      children: [
        // MAIN CATEGORIES
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF243A8F), width: 1),
          ),
          child: MainCategoriesGrid(
            selectedCategoryId: controller.selectedCategoryId,
            onCategorySelected: controller.selectCategory,
            categoryType: controller.categoryType,
            isCompactScreen: isCompactScreen,
          ),
        ),

        // SUB CATEGORIES
        if (!isKeyboardOpen && isExpense && controller.hasSubCategories)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF243A8F), width: 1),
            ),
            child: SubCategoriesGrid(
              subCategories: controller.currentSubCategories,
              selectedSubCategoryId: controller.selectedCategoryId,
              onSubCategorySelected: controller.selectCategory,
            ),
          ),

        const Spacer(),

        // AMOUNT INPUT PANEL
        AmountInputPanel(
          controller: controller,
          onAccountTap: () {
            _showAccountPicker(context, controller);
          },
        ),
      ],
    );
  }
}

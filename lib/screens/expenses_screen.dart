// lib/screens/expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/transaction_entry_controller.dart';
import '../widgets/expense_entry/expense_entry_tabs.dart';
import '../widgets/expense_entry/main_categories_grid.dart';
import '../widgets/expense_entry/sub_categories_grid.dart';
import '../widgets/expense_entry/amount_input_panel.dart';
import '../widgets/expense_entry/quick_actions_row.dart';
import '../widgets/expense_entry/action_buttons_row.dart';
import '../widgets/expense_entry/advanced_options_panel.dart';
import '../widgets/expense_entry/transfer_form.dart';
import '../l10n/app_localizations.dart';
import '../constants/transaction_constants.dart';

class ExpensesScreen extends StatelessWidget {
  final String initialType;

  const ExpensesScreen({super.key, this.initialType = TransactionType.expense});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = TransactionEntryController();
        controller.setTransactionType(initialType);
        return controller;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            initialType == TransactionType.income
                ? AppLocalizations.of(context)!.income
                : (initialType == TransactionType.transfer
                      ? AppLocalizations.of(context)!.transfer
                      : AppLocalizations.of(context)!.expenses),
          ),
          backgroundColor: const Color(0xFF0A0A0A),
        ),
        body: Consumer<TransactionEntryController>(
          builder: (context, controller, _) {
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final keyboardHeight = MediaQuery.of(
                    context,
                  ).viewInsets.bottom;
                  final isKeyboardOpen = keyboardHeight > 0;
                  final isTransfer =
                      controller.selectedTransactionType ==
                      TransactionType.transfer;
                  final isExpense = controller.isExpense;

                  return Column(
                    children: [
                      ExpenseEntryTabs(controller: controller),
                      const SizedBox(height: 8),
                      if (isTransfer)
                        Expanded(child: TransferForm(controller: controller))
                      else
                        Expanded(
                          child: _buildExpenseIncomeContent(
                            controller: controller,
                            isKeyboardOpen: isKeyboardOpen,
                            isExpense: isExpense,
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseIncomeContent({
    required TransactionEntryController controller,
    required bool isKeyboardOpen,
    required bool isExpense,
  }) {
    return Column(
      children: [
        Expanded(
          flex: isKeyboardOpen ? 2 : 4,
          child: MainCategoriesGrid(
            selectedCategoryId: controller.selectedCategoryId,
            onCategorySelected: controller.selectCategory,
            categoryType: controller.categoryType,
          ),
        ),
        const SizedBox(height: 8),
        if (controller.hasSubCategories && !isKeyboardOpen && isExpense)
          SizedBox(
            height: 120,
            child: SubCategoriesGrid(
              subCategories: controller.currentSubCategories,
              selectedSubCategoryId: controller.selectedCategoryId,
              onSubCategorySelected: controller.selectCategory,
            ),
          ),
        Flexible(
          flex: isKeyboardOpen ? 2 : 3,
          child: AmountInputPanel(controller: controller),
        ),
        if (!isKeyboardOpen && isExpense) ...[
          QuickActionsRow(controller: controller),
          const SizedBox(height: 8),
          AdvancedOptionsPanel(controller: controller),
          const SizedBox(height: 8),
        ],
        ActionButtonsRow(controller: controller),
      ],
    );
  }
}

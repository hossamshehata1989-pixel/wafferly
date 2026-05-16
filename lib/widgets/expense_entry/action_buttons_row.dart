// lib/widgets/expense_entry/action_buttons_row.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/transaction_constants.dart';

class ActionButtonsRow extends StatelessWidget {
  final TransactionEntryController controller;

  const ActionButtonsRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isSaving = controller.saveStatus == SaveStatus.saving;
    final isIncome = controller.isIncome;

    if (isIncome) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isSaving ? null : () => _handleSave(context, false, t),
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  t.saveIncome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSaving ? null : () => _handleSave(context, false, t),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      t.normalExpense,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSaving ? null : () => _handleSave(context, true, t),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      t.exceptionalExpense,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    bool isExceptional,
    AppLocalizations t,
  ) async {
    final result = await controller.validateAndSave(
      isExceptional: isExceptional,
    );

    if (!result.success) {
      switch (result.action) {
        case SaveAction.invalidAmount:
          _showSnackBar(context, t.pleaseEnterValidAmount);
          break;
        case SaveAction.noCategorySelected:
          _showSnackBar(context, t.pleaseSelectCategory);
          break;
        case SaveAction.noAccountSelected:
          _showSnackBar(context, t.pleaseSelectAccount);
          break;
        case SaveAction.insufficientBalance:
          final shortage = result.data?['shortage'] ?? 0;
          await _showInsufficientDialog(context, shortage, isExceptional, t);
          break;
        default:
          break;
      }
    } else {
      final message = controller.isIncome
          ? t.incomeAddedSuccessfully
          : t.expenseAddedSuccessfully;
      _showSnackBar(context, message);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showInsufficientDialog(
    BuildContext context,
    double shortage,
    bool isExceptional,
    AppLocalizations t,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: Text(
          t.insufficientBalanceTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '${t.insufficientBalanceMessage} ${shortage.toInt()}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'add_income'),
            child: Text(
              t.addBalance,
              style: const TextStyle(color: Colors.green),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'temp_debt'),
            child: Text(
              t.tempDebt,
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (action == 'add_income') {
      controller.setTransactionType(TransactionType.income);
      controller.setAmount(shortage.toString());
      if (context.mounted) _showSnackBar(context, t.expenseAddedAfterBalance);
    } else if (action == 'temp_debt') {
      await controller.addBalanceAndRetry(shortage);
      if (context.mounted) _showSnackBar(context, t.tempDebtSavedSuccessfully);
    }
  }
}

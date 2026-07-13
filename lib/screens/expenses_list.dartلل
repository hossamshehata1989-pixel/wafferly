// lib/screens/expenses_list.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_helper.dart';
import '../widgets/add_expense_bottom_sheet.dart';
import '../services/transaction_service.dart';
import '../constants/transaction_constants.dart';  // ✅ ADDED for TransactionType

class ExpensesList extends StatelessWidget {
  const ExpensesList({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");
    final box = Hive.box<Transaction>('transactions');
    final t = AppLocalizations.of(context)!;

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Transaction> box, _) {
        // ✅ استفاده از TransactionType.expense
        final transactions = box.values
            .where((t) => t.type == TransactionType.expense)
            .toList()
            .reversed
            .toList();

        if (transactions.isEmpty) {
          return Center(
            child: Text(
              t.noExpensesYet,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final txn = transactions[index];
            final txnKey = box.keyAt(box.values.toList().indexOf(txn));

            return Dismissible(
              key: Key(txn.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1B2A6B),
                    title: const Text(
                      'حذف المصروف',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'هل أنت متأكد من حذف هذا المصروف؟',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('حذف', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                await TransactionService.instance.deleteTransaction(txn.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.expenseDeletedSuccessfully),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: const Color(0xFF1B2A6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: txn.isExceptional ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: txn.isExceptional ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    child: Icon(
                      txn.isExceptional ? Icons.warning_rounded : Icons.repeat,
                      color: txn.isExceptional ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    getMainCategoryName(txn.categoryId, t),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${txn.subCategoryId != null 
                        ? getSubCategoryName(txn.subCategoryId!, t) 
                        : getMainCategoryName(txn.categoryId, t)} • ${txn.date.day}/${txn.date.month}/${txn.date.year}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${formatter.format(txn.amount.toInt())} EGP",
                        style: TextStyle(
                          color: txn.isExceptional ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () {
                            final categoryNotifier = ValueNotifier(
                              SelectedCategory(
                                id: txn.subCategoryId ?? txn.categoryId,
                                name: getMainCategoryName(txn.categoryId, t),
                              ),
                            );
                            showAddExpenseSheet(
                              context,
                              categoryNotifier,
                              expenseToEdit: txn,
                              expenseKey: txnKey,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
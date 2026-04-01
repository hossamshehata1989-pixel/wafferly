// lib/screens/expenses_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../widgets/add_expense_bottom_sheet.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");
    final box = Hive.box<Expense>('expenses');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Expense> box, _) {
        final expenses = box.values.toList().reversed.toList();

        if (expenses.isEmpty) {
          return const Center(
            child: Text(
              "No expenses yet",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index];
            final expenseKey = box.keyAt(box.values.toList().indexOf(e));

            return Dismissible(
              key: Key(e.id),
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
                await box.delete(expenseKey);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف المصروف بنجاح'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
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
                    color: e.isExceptional ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: e.isExceptional ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    child: Icon(
                      e.isExceptional ? Icons.warning_rounded : Icons.repeat,
                      color: e.isExceptional ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    e.mainCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${e.subCategory} • ${e.date.day}/${e.date.month}/${e.date.year}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${formatter.format(e.amount.toInt())} EGP",
                        style: TextStyle(
                          color: e.isExceptional ? Colors.orange : Colors.green,
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
                                id: e.subCategory,
                                name: e.mainCategory,
                              ),
                            );
                            showAddExpenseSheet(
                              context,
                              categoryNotifier,
                              expenseToEdit: e,
                              expenseKey: expenseKey,
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
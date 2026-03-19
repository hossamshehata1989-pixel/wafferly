// =====================================================
// 💸 Expenses List (Hive + Live Update)
// =====================================================

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({super.key});

  @override
  Widget build(BuildContext context) {

    final box = Hive.box<Expense>('expenses');

    return ValueListenableBuilder(

      // -------------------------------------------------
      // 🔥 Listen to Hive changes
      // -------------------------------------------------
      valueListenable: box.listenable(),

      builder: (context, Box<Expense> box, _) {

        final expenses = box.values.toList().reversed.toList();

        // -------------------------------------------------
        // ❗ لو مفيش بيانات
        // -------------------------------------------------
        if (expenses.isEmpty) {
          return const Center(
            child: Text(
              "No expenses yet",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        // -------------------------------------------------
        // 📋 List
        // -------------------------------------------------
        return ListView.builder(
          itemCount: expenses.length,

          itemBuilder: (context, index) {

            final e = expenses[index];

            return ListTile(

              title: Text(
                e.title,
                style: const TextStyle(color: Colors.white),
              ),

              subtitle: Text(
                e.category,
                style: const TextStyle(color: Colors.white70),
              ),

              trailing: Text(
                "${e.amount} EGP",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            );
          },
        );
      },
    );
  }
}
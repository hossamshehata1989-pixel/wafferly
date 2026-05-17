import 'package:flutter/material.dart';
import '../budget_card.dart';

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Monthly Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 12),

                Text("Spent: 4300"),
                Text("Budget: 7000"),

                SizedBox(height: 12),

                LinearProgressIndicator(value: 0.61),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        BudgetCard(
          icon: "🍔",
          title: "Food",
          spent: 1200,
          total: 1500,
          progress: 0.8,
          bucketEnabled: true,
        ),

        SizedBox(height: 12),

        BudgetCard(
          icon: "👕",
          title: "Clothes",
          spent: 700,
          total: 2000,
          progress: 0.35,
          bucketEnabled: false,
        ),

        SizedBox(height: 12),

        BudgetCard(
          icon: "🚕",
          title: "Transport",
          spent: 900,
          total: 1000,
          progress: 0.9,
          bucketEnabled: true,
        ),
      ],
    );
  }
}

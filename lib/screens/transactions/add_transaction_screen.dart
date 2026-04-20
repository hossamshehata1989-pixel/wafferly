// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class AddTransactionScreen extends StatefulWidget {
  final String type; // "expense" or "income"

  const AddTransactionScreen({super.key, required this.type});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final amountController = TextEditingController();
  String selectedAccountId = "";

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsBox = Hive.box<Account>('accounts');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == "expense" ? "Add Expense" : "Add Income"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Amount",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedAccountId.isEmpty ? null : selectedAccountId,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: accountsBox.values.map<DropdownMenuItem<String>>((acc) {
                return DropdownMenuItem(
                  value: acc.id,
                  child: Text(acc.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedAccountId = val ?? "";
                });
              },
              decoration: const InputDecoration(
                labelText: "Account",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    final amount = double.tryParse(amountController.text) ?? 0;

    if (amount == 0 || selectedAccountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid amount and select account"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final transactionsBox = Hive.box<Transaction>('transactions');

    await transactionsBox.add(
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.type,
        amount: amount,
        fromAccountId: widget.type == "expense" ? selectedAccountId : null,
        toAccountId: widget.type == "income" ? selectedAccountId : null,
        categoryId: "manual",
        date: DateTime.now(),
        paymentMethod: "cash",
        note: null,
        isExceptional: false,
        subCategoryId: null,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.type == "expense" ? "Expense added" : "Income added"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
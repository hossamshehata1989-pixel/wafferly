// lib/screens/accounts/add_account_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/account.dart';  // ✅ صح: ../../ مو ../../../
import '../../models/transaction.dart';
import '../../services/account_service.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final nameController = TextEditingController();
  final balanceController = TextEditingController();
  String selectedType = "cash";

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Account"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Account Name",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Initial Balance (EGP)",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: "cash", child: Text("Cash")),
                DropdownMenuItem(value: "bank", child: Text("Bank")),
                DropdownMenuItem(value: "wallet", child: Text("Wallet")),
                DropdownMenuItem(value: "creditCard", child: Text("Credit Card")),
                DropdownMenuItem(value: "loan", child: Text("Loan")),
                DropdownMenuItem(value: "investment", child: Text("Investment")),
                DropdownMenuItem(value: "lent", child: Text("Money Lent")),
              ],
              onChanged: (val) => setState(() => selectedType = val!),
              decoration: const InputDecoration(
                labelText: "Account Type",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Save Account",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAccount() async {
    final name = nameController.text.trim();
    final initialBalance = double.tryParse(balanceController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter account name"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final accountId = DateTime.now().millisecondsSinceEpoch.toString();
    final nature = _getNature(selectedType);

    final account = Account(
      id: accountId,
      bookId: "personal",
      name: name,
      type: selectedType,
      nature: nature,
      currency: "EGP",
      createdAt: DateTime.now(),
    );

    await AccountService().addAccount(account);

    // ✅ إضافة الرصيد الافتتاحي كمعاملة (لحسابات الأصول فقط)
    if (initialBalance > 0 && nature == 'asset') {
      final transactionsBox = Hive.box<Transaction>('transactions');
      await transactionsBox.add(
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: "initial_balance",
          amount: initialBalance,
          fromAccountId: null,
          toAccountId: accountId,
          categoryId: "initial_balance",
          date: DateTime.now(),
          note: "Initial balance",
          isExceptional: false,
          paymentMethod: selectedType,
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added with ${initialBalance.toStringAsFixed(0)} EGP'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _getNature(String type) {
    if (type == "creditCard" || type == "loan") {
      return "liability";
    }
    return "asset";
  }
}
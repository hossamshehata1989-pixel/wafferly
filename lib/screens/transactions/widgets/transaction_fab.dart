// lib/screens/transactions/widgets/transaction_fab.dart

import 'package:flutter/material.dart';
import '../../expenses_screen.dart';

class TransactionFab extends StatelessWidget {
  final VoidCallback onTransactionAdded;

  const TransactionFab({super.key, required this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "transactionTabFab",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpensesScreen()),
        ).then((_) {
          onTransactionAdded();
        });
      },
      backgroundColor: const Color(0xFF3A7BFF),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

// lib/screens/transactions/widgets/transaction_fab.dart

import 'package:flutter/material.dart';
import 'add_transaction_bottom_sheet.dart';

class TransactionFab extends StatelessWidget {
  final VoidCallback onTransactionAdded;

  const TransactionFab({super.key, required this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "transactionTabFab",
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              AddTransactionBottomSheet(onTransactionAdded: onTransactionAdded),
        );
      },
      backgroundColor: const Color(0xFF3A7BFF),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

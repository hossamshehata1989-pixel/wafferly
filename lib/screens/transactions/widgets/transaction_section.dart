// lib/screens/transactions/widgets/transaction_section.dart

import 'package:flutter/material.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/screens/transactions/widgets/transaction_card.dart';

class TransactionSection extends StatefulWidget {
  final String title;
  final List<Transaction> transactions;
  final VoidCallback onTransactionDeleted;
  final VoidCallback onTransactionUpdated;
  final String Function(String?) getAccountName;

  const TransactionSection({
    super.key,
    required this.title,
    required this.transactions,
    required this.onTransactionDeleted,
    required this.onTransactionUpdated,
    required this.getAccountName,
  });

  @override
  State<TransactionSection> createState() => _TransactionSectionState();
}

class _TransactionSectionState extends State<TransactionSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.transactions.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Column(
              children: widget.transactions
                  .map<Widget>(
                    (tx) => TransactionCard(
                      transaction: tx,
                      onDeleted: widget.onTransactionDeleted,
                      onUpdated: widget.onTransactionUpdated,
                      getAccountName: widget.getAccountName,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

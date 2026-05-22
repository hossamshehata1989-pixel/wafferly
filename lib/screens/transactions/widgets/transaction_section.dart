// lib/screens/transactions/widgets/transaction_section.dart

import 'package:flutter/material.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/screens/transactions/widgets/transaction_card.dart';

class TransactionSection extends StatefulWidget {
  final String title;
  final List<Transaction> transactions;
  final Function(String) onDeleteTransaction;
  final Function(Transaction) onEditTransaction;
  final String Function(String?) getAccountName;

  const TransactionSection({
    super.key,
    required this.title,
    required this.transactions,
    required this.onDeleteTransaction,
    required this.onEditTransaction,
    required this.getAccountName,
  });

  @override
  State<TransactionSection> createState() => _TransactionSectionState();
}

class _TransactionSectionState extends State<TransactionSection> {
  bool _isExpanded = true;

  void _handleDelete(String transactionId) {
    widget.onDeleteTransaction(transactionId);
  }

  void _handleEdit(Transaction transaction) {
    widget.onEditTransaction(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.transactions.length;
    final label = itemCount == 1 ? '1 transaction' : '$itemCount transactions';

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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
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
                      onDeleted: () => _handleDelete(tx.id),
                      onEdit: () => _handleEdit(tx),
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

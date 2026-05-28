// lib/screens/transactions/widgets/transaction_section.dart

import 'package:flutter/material.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/screens/transactions/widgets/transaction_card.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/screens/transactions/widgets/day_section_header.dart';

class TransactionSection extends StatefulWidget {
  final String title;
  final List<Transaction> transactions;
  final Function(String) onDeleteTransaction;
  final Function(Transaction) onEditTransaction;
  final String Function(String?) getAccountName;
  final int selectedTab;
  final double totalAmount;

  const TransactionSection({
    super.key,
    required this.title,
    required this.transactions,
    required this.onDeleteTransaction,
    required this.onEditTransaction,
    required this.getAccountName,
    required this.selectedTab,
    required this.totalAmount,
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: DaySectionHeader(
                title: widget.title,
                count: widget.transactions.length,
                selectedTab: widget.selectedTab,
                totalAmount: widget.totalAmount,
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

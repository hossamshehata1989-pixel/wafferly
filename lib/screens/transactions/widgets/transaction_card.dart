// lib/screens/transactions/widgets/transaction_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wafferly/models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDeleted;
  final VoidCallback onEdit;
  final String Function(String?) getAccountName;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDeleted,
    required this.onEdit,
    required this.getAccountName,
  });

  Color _getAmountColor() {
    switch (transaction.type) {
      case 'expense':
        return Colors.red;
      case 'income':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  String _getAmountPrefix() {
    switch (transaction.type) {
      case 'expense':
        return '-';
      case 'income':
        return '+';
      case 'transfer':
        return '';
      default:
        return '';
    }
  }

  String _getAmountSuffix() {
    switch (transaction.type) {
      case 'expense':
        return '↑';
      case 'income':
        return '↓';
      default:
        return '';
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String _getTitle() {
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    return transaction.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");
    final accountName = getAccountName(
      transaction.type == 'expense'
          ? transaction.fromAccountId
          : transaction.toAccountId,
    );

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDeleted();
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A6B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(
                  minWidth: 40,
                  maxWidth: 44,
                  minHeight: 40,
                  maxHeight: 44,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$accountName • ${transaction.categoryId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatTime(transaction.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: Text(
                  '${_getAmountPrefix()}${formatter.format(transaction.amount.toInt())} EGP ${_getAmountSuffix()}',
                  style: TextStyle(
                    color: _getAmountColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

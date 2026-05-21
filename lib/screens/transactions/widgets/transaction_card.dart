// lib/screens/transactions/widgets/transaction_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/transaction_service.dart';
import '../../../constants/transaction_constants.dart';
import 'package:wafferly/models/transaction.dart';
import '../../../l10n/app_localizations.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;
  final String Function(String?) getAccountName;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDeleted,
    required this.onUpdated,
    required this.getAccountName,
  });

  Color _getAmountColor() {
    switch (transaction.type) {
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.income:
        return Colors.green;
      case TransactionType.transfer:
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  String _getAmountPrefix() {
    switch (transaction.type) {
      case TransactionType.expense:
        return '-';
      case TransactionType.income:
        return '+';
      case TransactionType.transfer:
        return '';
      default:
        return '';
    }
  }

  String _getAmountSuffix() {
    switch (transaction.type) {
      case TransactionType.expense:
        return '↑';
      case TransactionType.income:
        return '↓';
      default:
        return '';
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text(
          'Delete Transaction',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this transaction?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TransactionService.instance.deleteTransaction(transaction.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        onDeleted();
      }
    }
  }

  // TODO: Edit functionality will be implemented later
  void _onEdit(BuildContext context) {
    // Placeholder - edit coming soon
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");
    final accountName = getAccountName(
      transaction.type == TransactionType.expense
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
          await _confirmDelete(context);
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          _onEdit(context);
          return false;
        }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80),
                child: Text(
                  '${_getAmountPrefix()}${formatter.format(transaction.amount.toInt())} EGP ${_getAmountSuffix()}',
                  style: TextStyle(
                    color: _getAmountColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    return transaction.categoryId;
  }
}

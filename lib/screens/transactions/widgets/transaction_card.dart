// lib/screens/transactions/widgets/transaction_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/utils/category_icons.dart';

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

  String _getSubCategory() {
    if (transaction.subCategoryId != null &&
        transaction.subCategoryId!.isNotEmpty) {
      return transaction.subCategoryId!;
    }
    return transaction.categoryId;
  }

  String _getMainCategory() {
    return transaction.categoryId;
  }

  String _getCategoryIconPath() {
    final categoryId = _getSubCategory();
    final iconPath = getCategoryIcon(categoryId);
    return iconPath;
  }

  String _getTitle() {
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    return _getSubCategory();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###");
    final accountName = getAccountName(
      transaction.type == 'expense'
          ? transaction.fromAccountId
          : transaction.toAccountId,
    );
    final mainCategory = _getMainCategory();
    final time = _formatTime(transaction.date);
    final iconPath = _getCategoryIconPath();

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
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }

        if (direction == DismissDirection.endToStart) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Transaction'),
              content: const Text(
                'Are you sure you want to delete this transaction?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            onDeleted();
            return false;
          }

          return false;
        }

        return false;
      },

      onDismissed: (_) {},

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A6B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.category, size: 18, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mainCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            accountName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 85,
                child: Text(
                  '${_getAmountPrefix()}${formatter.format(transaction.amount.toInt())}',
                  style: TextStyle(
                    color: _getAmountColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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

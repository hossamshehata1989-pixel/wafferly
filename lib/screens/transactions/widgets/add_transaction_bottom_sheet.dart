// lib/screens/transactions/widgets/add_transaction_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../../controllers/transaction_entry_controller.dart';
import '../../../constants/transaction_constants.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final VoidCallback onTransactionAdded;

  const AddTransactionBottomSheet({
    super.key,
    required this.onTransactionAdded,
  });

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  int _selectedType =
      0; // 0: Expense, 1: Income, 2: Transfer, 3: Borrow/Lend, 4: Payment

  final List<Map<String, dynamic>> _types = const [
    {
      'icon': Icons.receipt_long,
      'label': 'Expense',
      'type': TransactionType.expense,
    },
    {
      'icon': Icons.trending_up,
      'label': 'Income',
      'type': TransactionType.income,
    },
    {
      'icon': Icons.swap_horiz,
      'label': 'Transfer',
      'type': TransactionType.transfer,
    },
    {
      'icon': Icons.handshake,
      'label': 'Borrow/Lend',
      'type': TransactionType.expense,
    }, // Placeholder
    {
      'icon': Icons.payment,
      'label': 'Payment',
      'type': TransactionType.expense,
    }, // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'New Transaction',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _types.asMap().entries.map((entry) {
                final index = entry.key;
                final type = entry.value;
                final isSelected = _selectedType == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3A7BFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type['icon'],
                            color: isSelected ? Colors.white : Colors.white54,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Transaction form for ${_types[_selectedType]['label']} will be implemented here',
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

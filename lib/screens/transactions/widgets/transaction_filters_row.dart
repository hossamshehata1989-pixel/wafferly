import 'package:flutter/material.dart';

class TransactionFiltersRow extends StatelessWidget {
  const TransactionFiltersRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Chip(label: Text('Date')),
          SizedBox(width: 8),
          Chip(label: Text('Members')),
          SizedBox(width: 8),
          Chip(label: Text('Categories')),
          SizedBox(width: 8),
          Chip(label: Text('Sort')),
        ],
      ),
    );
  }
}

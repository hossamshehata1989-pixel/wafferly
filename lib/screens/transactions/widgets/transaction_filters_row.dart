// lib/screens/transactions/widgets/transaction_filters_row.dart

import 'package:flutter/material.dart';

class TransactionFiltersRow extends StatelessWidget {
  const TransactionFiltersRow({super.key});

  void _showDateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Date Range',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(context, 'Today'),
              _buildFilterOption(context, 'This week'),
              _buildFilterOption(context, 'This month'),
              _buildFilterOption(context, 'Custom range'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BFF),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(context, 'Latest first'),
              _buildFilterOption(context, 'Oldest first'),
              _buildFilterOption(context, 'Highest amount'),
              _buildFilterOption(context, 'Lowest amount'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BFF),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String label) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label selected (coming soon)'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ActionChip(
            label: const Text('Date'),
            onPressed: () => _showDateSheet(context),
            avatar: const Icon(Icons.calendar_today, size: 16),
            backgroundColor: const Color(0xFF1A1A1A),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Members'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Members filter coming soon'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 1),
              ),
            ),
            avatar: const Icon(Icons.people, size: 16),
            backgroundColor: const Color(0xFF1A1A1A),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Categories'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Categories filter coming soon'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 1),
              ),
            ),
            avatar: const Icon(Icons.category, size: 16),
            backgroundColor: const Color(0xFF1A1A1A),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Sort'),
            onPressed: () => _showSortSheet(context),
            avatar: const Icon(Icons.sort, size: 16),
            backgroundColor: const Color(0xFF1A1A1A),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

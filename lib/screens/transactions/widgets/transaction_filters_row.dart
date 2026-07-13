// lib/screens/transactions/widgets/transaction_filters_row.dart

import 'package:flutter/material.dart';
import 'package:wafferly/services/account_service.dart';

class TransactionFiltersRow extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final VoidCallback onCategoryPressed;

  const TransactionFiltersRow({
    super.key,
    required this.onFiltersChanged,
    required this.onCategoryPressed,
  });

  @override
  State<TransactionFiltersRow> createState() => _TransactionFiltersRowState();
}

class _TransactionFiltersRowState extends State<TransactionFiltersRow> {
  final AccountService _accountService = AccountService();

  String _selectedDate = 'This Month';
  String _selectedMembers = 'All Members';
  String _selectedAccount = 'All Accounts';
  final String _selectedCategory = 'All Categories';
  String _selectedSort = 'Recent First';

  List<String> _getAccountNames() {
    final accounts = _accountService.getAllActiveAccounts();

    return ['All Accounts', ...accounts.map((a) => a.name)];
  }

  void _applyFilters() {
    widget.onFiltersChanged({
      'date': _selectedDate,
      'members': _selectedMembers,
      'account': _selectedAccount,
      'category': _selectedCategory,
      'sort': _selectedSort,
    });
  }

  Widget _buildFilterOption(
    BuildContext context,
    String label,
    VoidCallback onSelected,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onSelected,
    );
  }

  void _showDateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .7,
              child: Column(
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

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final date in [
                            'Today',
                            'Last 3 Days',
                            'Last 7 Days',
                            'This Month',
                            'Last 3 Months',
                            'This Year',
                            'All Time',
                          ])
                            _buildFilterOption(context, date, () {
                              setState(() {
                                _selectedDate = date;
                              });
                            }),
                        ],
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BFF),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return ListTile(
          title: const Text(
            'All Members',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {
            setState(() {
              _selectedMembers = 'All Members';
            });

            Navigator.pop(context);
            _applyFilters();
          },
        );
      },
    );
  }

  void _showAccountsSheet() {
    final accountNames = _getAccountNames();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .7,
              child: Column(
                children: [
                  const Text(
                    'Accounts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: accountNames
                            .map(
                              (name) => _buildFilterOption(context, name, () {
                                setState(() {
                                  _selectedAccount = name;
                                });
                              }),
                            )
                            .toList(),
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      _applyFilters();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSortSheet() {
    final sorts = [
      'Recent First',
      'Oldest First',
      'Highest Amount',
      'Lowest Amount',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: sorts
              .map(
                (s) => _buildFilterOption(context, s, () {
                  setState(() {
                    _selectedSort = s;
                  });

                  Navigator.pop(context);

                  _applyFilters();
                }),
              )
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(label: Text(_selectedDate), onPressed: _showDateSheet),

          const SizedBox(width: 8),

          ActionChip(
            label: Text(_selectedMembers),
            onPressed: _showMembersSheet,
          ),

          const SizedBox(width: 8),

          ActionChip(
            label: Text(_selectedAccount),
            onPressed: _showAccountsSheet,
          ),

          const SizedBox(width: 8),

          ActionChip(
            label: Text(
              _selectedCategory == 'All Categories'
                  ? 'Categories'
                  : _selectedCategory,
            ),
            onPressed: widget.onCategoryPressed,
          ),

          const SizedBox(width: 8),

          ActionChip(label: Text(_selectedSort), onPressed: _showSortSheet),
        ],
      ),
    );
  }
}

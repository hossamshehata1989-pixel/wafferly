// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';
import '../../services/account_service.dart';
import '../../models/transaction.dart';
import '../../constants/transaction_constants.dart';
import 'package:wafferly/screens/transactions/widgets/transaction_tab_bar.dart';
import 'package:wafferly/screens/transactions/widgets/transaction_filters_row.dart';
import 'package:wafferly/screens/transactions/widgets/transaction_section.dart';
import 'package:wafferly/screens/transactions/widgets/transaction_fab.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedTab = 0;
  List<Transaction> _allTransactions = [];
  List<_DateGroup> _dateGroups = [];

  final TransactionService _transactionService = TransactionService.instance;
  final AccountService _accountService = AccountService();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      _allTransactions = _transactionService.getAllTransactions();
      _dateGroups = _groupTransactionsByDate(_getFilteredTransactions());
    });
  }

  List<Transaction> _getFilteredTransactions() {
    if (_selectedTab == 0) {
      return _allTransactions
          .where((t) => t.type == TransactionType.expense)
          .toList();
    } else if (_selectedTab == 1) {
      return _allTransactions
          .where((t) => t.type == TransactionType.income)
          .toList();
    } else if (_selectedTab == 2) {
      return _allTransactions
          .where((t) => t.type == TransactionType.transfer)
          .toList();
    } else if (_selectedTab == 3 || _selectedTab == 4) {
      // Borrow/Lend and Payments - placeholder until dedicated transaction types exist
      return [];
    }
    return _allTransactions;
  }

  List<_DateGroup> _groupTransactionsByDate(List<Transaction> transactions) {
    final Map<String, _DateGroup> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String groupKey;
      String title;

      if (txDate == today) {
        groupKey = 'today';
        title = 'Today';
      } else if (txDate == yesterday) {
        groupKey = 'yesterday';
        title = 'Yesterday';
      } else {
        // Group by Month + Year
        groupKey = '${tx.date.year}-${tx.date.month}';
        title = '${_getMonthName(tx.date.month)} ${tx.date.year}';
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = _DateGroup(
          date: txDate,
          title: title,
          transactions: [],
          sortKey: groupKey,
        );
      }
      groups[groupKey]!.transactions.add(tx);
    }

    // Sort: Today first, then Yesterday, then by date descending
    final sortedGroups = groups.values.toList()
      ..sort((a, b) {
        if (a.sortKey == 'today') return -1;
        if (b.sortKey == 'today') return 1;
        if (a.sortKey == 'yesterday') return -1;
        if (b.sortKey == 'yesterday') return 1;
        return b.date.compareTo(a.date);
      });

    return sortedGroups;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getAccountName(String? accountId) {
    if (accountId == null) return 'Unknown';

    try {
      final account = _accountService.getAllAccounts().firstWhere(
        (a) => a.id == accountId,
      );

      return account.name;
    } catch (_) {
      return 'Unknown';
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
      _dateGroups = _groupTransactionsByDate(_getFilteredTransactions());
    });
  }

  void _refreshTransactions() {
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final hasTransactions = _dateGroups.isNotEmpty;
    final hasAnyTransaction = _allTransactions.isNotEmpty;
    final isPlaceholderTab =
        (_selectedTab == 3 || _selectedTab == 4) && _dateGroups.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          TransactionTabBar(onTabChanged: _onTabChanged),
          TransactionFiltersRow(),
          Expanded(
            child: isPlaceholderTab
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.build,
                          size: 64,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Coming Soon',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This transaction type will be available in a future update',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : !hasTransactions && hasAnyTransaction
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions in this category',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : !hasTransactions
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first transaction',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _dateGroups.length,
                    itemBuilder: (context, index) {
                      final group = _dateGroups[index];
                      return TransactionSection(
                        title: group.title,
                        transactions: group.transactions,
                        onTransactionDeleted: _refreshTransactions,
                        onTransactionUpdated: _refreshTransactions,
                        getAccountName: _getAccountName,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: TransactionFab(
        onTransactionAdded: _refreshTransactions,
      ),
    );
  }
}

// Internal class for date grouping
class _DateGroup {
  final DateTime date;
  final String title;
  final List<Transaction> transactions;
  final String sortKey;

  _DateGroup({
    required this.date,
    required this.title,
    required this.transactions,
    required this.sortKey,
  });
}

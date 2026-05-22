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

  void _showSearchSheet() {
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
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A7BFF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BFF),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
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
                'Advanced Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Colors.white54,
                ),
                title: const Text(
                  'Date Range',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.category, color: Colors.white54),
                title: const Text(
                  'Categories',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white54,
                ),
                title: const Text(
                  'Accounts',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BFF),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      return [];
    }
    return _allTransactions;
  }

  List<_DateGroup> _groupTransactionsByDate(List<Transaction> transactions) {
    final Map<String, _DateGroup> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String groupKey;
      String title;

      if (txDate == today) {
        groupKey = 'today';
        title = 'Today';
      } else if (txDate.isAfter(now.subtract(const Duration(days: 7))) &&
          txDate.isBefore(now.add(const Duration(days: 1)))) {
        // Within last 7 days - show weekday name
        final weekday = _getWeekdayName(txDate.weekday);
        groupKey = 'week_${txDate.weekday}';
        title = weekday;
      } else if (txDate.isAfter(startOfWeek) &&
          txDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        // Current week - show date range
        groupKey = 'current_week';
        title =
            '${startOfWeek.day}/${startOfWeek.month} → ${endOfWeek.day}/${endOfWeek.month}';
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

    final sortedGroups = groups.values.toList()
      ..sort((a, b) {
        if (a.sortKey == 'today') return -1;
        if (b.sortKey == 'today') return 1;
        if (a.sortKey.startsWith('week_')) return -1;
        if (b.sortKey.startsWith('week_')) return 1;
        if (a.sortKey == 'current_week') return -1;
        if (b.sortKey == 'current_week') return 1;
        return b.date.compareTo(a.date);
      });

    return sortedGroups;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
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

  void _handleDeleteTransaction(String transactionId) async {
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
      final transaction = _allTransactions.firstWhere(
        (t) => t.id == transactionId,
      );
      await TransactionService.instance.deleteTransaction(transactionId);
      _refreshTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                await TransactionService.instance.addTransaction(transaction);
                _refreshTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction restored'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _handleEditTransaction(Transaction transaction) {
    // Placeholder - edit coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit coming soon'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
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
            onPressed: _showSearchSheet,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          TransactionTabBar(onTabChanged: _onTabChanged),
          const TransactionFiltersRow(),
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
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _dateGroups.length,
                    itemBuilder: (context, index) {
                      final group = _dateGroups[index];
                      return TransactionSection(
                        title: group.title,
                        transactions: group.transactions,
                        onDeleteTransaction: _handleDeleteTransaction,
                        onEditTransaction: _handleEditTransaction,
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

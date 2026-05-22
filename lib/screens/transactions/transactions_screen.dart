// lib/screens/transactions/transactions_screen.dart

import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';
import '../../services/account_service.dart';
import '../../models/transaction.dart';
import '../../constants/transaction_constants.dart';
import 'widgets/transaction_tab_bar.dart';
import 'widgets/transaction_filters_row.dart';
import 'widgets/transaction_section.dart';
import 'widgets/transaction_fab.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedTab = 0;
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  List<_DateGroup> _dateGroups = [];

  final TransactionService _transactionService = TransactionService.instance;
  final AccountService _accountService = AccountService();

  String _searchQuery = '';
  Map<String, dynamic> _filters = {
    'date': 'Today',
    'members': 'All Members',
    'account': 'All Accounts',
    'category': 'All Categories',
    'sort': 'Recent First',
  };

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _netBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      _allTransactions = _transactionService.getAllTransactions();
      _applyFiltersAndSearch();
    });
  }

  void _applyFiltersAndSearch() {
    List<Transaction> result = List.from(_allTransactions);

    result = _filterByTab(result, _selectedTab);

    if (_searchQuery.isNotEmpty) {
      result = _filterBySearch(result, _searchQuery);
    }

    if (_filters['account'] != 'All Accounts') {
      result = _filterByAccount(result, _filters['account']);
    }

    if (_filters['category'] != 'All Categories') {
      result = _filterByCategory(result, _filters['category']);
    }

    result = _applySort(result, _filters['sort']);

    final dateRange = _getDateRangeForFilter(_filters['date']);
    result = _filterByDateRange(result, dateRange);

    _calculateTotals(result);

    setState(() {
      _filteredTransactions = result;
      _dateGroups = _groupTransactionsByDate(
        _filteredTransactions,
        _filters['date'],
      );
    });
  }

  void _calculateTotals(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }
    _totalIncome = income;
    _totalExpense = expense;
    _netBalance = income - expense;
  }

  List<Transaction> _filterByTab(List<Transaction> transactions, int tabIndex) {
    if (tabIndex == 0) return transactions;
    if (tabIndex == 1)
      return transactions
          .where((t) => t.type == TransactionType.expense)
          .toList();
    if (tabIndex == 2)
      return transactions
          .where((t) => t.type == TransactionType.income)
          .toList();
    if (tabIndex == 3)
      return transactions
          .where((t) => t.type == TransactionType.transfer)
          .toList();
    if (tabIndex == 4) return [];
    if (tabIndex == 5) return [];
    return transactions;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  List<Transaction> _filterBySearch(
    List<Transaction> transactions,
    String query,
  ) {
    final normalizedQuery = _normalize(query);

    final List<Transaction> startsWith = [];
    final List<Transaction> contains = [];

    for (final tx in transactions) {
      final categoryMatch = _normalize(tx.categoryId);
      final subCategoryMatch = _normalize(tx.subCategoryId ?? '');
      final noteMatch = _normalize(tx.note ?? '');
      final accountMatch = _normalize(_getAccountNameForTransaction(tx));
      final amountMatch = tx.amount.toString();

      if (categoryMatch.startsWith(normalizedQuery) ||
          subCategoryMatch.startsWith(normalizedQuery) ||
          noteMatch.startsWith(normalizedQuery) ||
          accountMatch.startsWith(normalizedQuery) ||
          amountMatch.startsWith(normalizedQuery)) {
        startsWith.add(tx);
        continue;
      }

      if (categoryMatch.contains(normalizedQuery) ||
          subCategoryMatch.contains(normalizedQuery) ||
          noteMatch.contains(normalizedQuery) ||
          accountMatch.contains(normalizedQuery) ||
          amountMatch.contains(normalizedQuery)) {
        contains.add(tx);
      }
    }

    return [...startsWith, ...contains];
  }

  List<Transaction> _filterByAccount(
    List<Transaction> transactions,
    String accountName,
  ) {
    return transactions.where((tx) {
      final accountId = tx.type == TransactionType.expense
          ? tx.fromAccountId
          : tx.toAccountId;
      if (accountId == null) return false;
      try {
        final account = _accountService.getAllAccounts().firstWhere(
          (a) => a.id == accountId,
        );
        return account.name == accountName;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Transaction> _filterByCategory(
    List<Transaction> transactions,
    String category,
  ) {
    if (category == 'All Categories') return transactions;
    return transactions
        .where((tx) => tx.categoryId == category.toLowerCase())
        .toList();
  }

  List<Transaction> _applySort(List<Transaction> transactions, String sort) {
    final sorted = List<Transaction>.from(transactions);
    switch (sort) {
      case 'Recent First':
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Oldest First':
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Highest Amount':
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Lowest Amount':
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return sorted;
  }

  DateTimeRange _getDateRangeForFilter(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        final start = DateTime(now.year, now.month, now.day);

        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

        return DateTimeRange(start: start, end: end);
      case 'Last 3 Days':
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 2));
        final end = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: end);
      case 'Last Week':
        final start = now.subtract(const Duration(days: 7));
        final end = now;
        return DateTimeRange(start: start, end: end);
      case 'Last Month':
        final start = now.subtract(const Duration(days: 30));
        final end = now;
        return DateTimeRange(start: start, end: end);
      case 'Last 3 Months':
        final start = now.subtract(const Duration(days: 90));
        final end = now;
        return DateTimeRange(start: start, end: end);
      case 'Last Year':
        final start = now.subtract(const Duration(days: 365));
        final end = now;
        return DateTimeRange(start: start, end: end);
      case 'All Time':
        return DateTimeRange(start: DateTime(2020, 1, 1), end: now);
      default:
        final today = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: today, end: today);
    }
  }

  List<Transaction> _filterByDateRange(
    List<Transaction> transactions,
    DateTimeRange range,
  ) {
    return transactions.where((tx) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      return txDate.isAfter(range.start.subtract(const Duration(days: 1))) &&
          txDate.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  List<_DateGroup> _groupTransactionsByDate(
    List<Transaction> transactions,
    String dateFilter,
  ) {
    final Map<String, _DateGroup> groups = {};

    for (final tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String groupKey;
      String title;

      switch (dateFilter) {
        case 'Today':
        case 'Last 3 Days':
        case 'Last Week':
        case 'Last Month':
        case 'Last 3 Months':
        case 'Last Year':
        case 'All Time':
          title = '${txDate.day} ${_getMonthName(txDate.month)} ${txDate.year}';
          groupKey = txDate.toString();
          break;
        default:
          title = '${_getMonthName(txDate.month)} ${txDate.year}';
          groupKey = '${txDate.year}-${txDate.month}';
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = _DateGroup(
          date: txDate,
          title: title,
          transactions: [],
          sortKey: groupKey,
          totalAmount: 0,
        );
      }
      groups[groupKey]!.transactions.add(tx);
      groups[groupKey]!.totalAmount += tx.type == TransactionType.expense
          ? -tx.amount
          : tx.amount;
    }

    final sortedGroups = groups.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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

  String _getAccountNameForTransaction(Transaction tx) {
    final accountId = tx.type == TransactionType.expense
        ? tx.fromAccountId
        : tx.toAccountId;
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
      await TransactionService.instance.deleteTransaction(transactionId);
      _refreshTransactions();
    }
  }

  void _handleEditTransaction(Transaction transaction) {
    // Edit flow not implemented yet
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
      _applyFiltersAndSearch();
    });
  }

  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      _applyFiltersAndSearch();
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSearch();
    });
  }

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
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
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
                onChanged: (value) {
                  _onSearch(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshTransactions() {
    _loadTransactions();
  }

  Widget _buildSummaryCard() {
    final formatter = NumberFormat("#,###");
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A6B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Income',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${formatter.format(_totalIncome.toInt())} EGP',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Expenses',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '-${formatter.format(_totalExpense.toInt())} EGP',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Net',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_netBalance >= 0 ? '+' : ''}${formatter.format(_netBalance.toInt())} EGP',
                  style: TextStyle(
                    color: _netBalance >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTransactions = _dateGroups.isNotEmpty;
    final hasAnyTransaction = _allTransactions.isNotEmpty;

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
        ],
      ),
      body: Column(
        children: [
          TransactionTabBar(onTabChanged: _onTabChanged),
          TransactionFiltersRow(onFiltersChanged: _onFiltersChanged),
          if (_dateGroups.isNotEmpty) _buildSummaryCard(),
          Expanded(
            child: !hasTransactions && hasAnyTransaction
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
                          'No transactions match',
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
  double totalAmount;

  _DateGroup({
    required this.date,
    required this.title,
    required this.transactions,
    required this.sortKey,
    required this.totalAmount,
  });
}

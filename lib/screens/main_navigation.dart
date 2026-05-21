// lib/screens/main_navigation.dart

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

import 'accounts/accounts_screen.dart';
import 'expenses_screen.dart';
import 'transactions/transactions_screen.dart';
import 'planning/planning_screen.dart';
import '../constants/transaction_constants.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AccountsScreen(),
    TransactionsScreen(),
    PlanningScreen(),
    SettingsPlaceholder(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTransactionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inactive,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: t.accounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_graph),
            label: t.planning,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: t.settings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBottomSheet,
        backgroundColor: const Color(0xFF3A7BFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Settings placeholder (temporary)
class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F1115),
      body: Center(
        child: Text('Settings', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// Global FAB Bottom Sheet
class _AddTransactionBottomSheet extends StatefulWidget {
  @override
  State<_AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends State<_AddTransactionBottomSheet> {
  final List<Map<String, dynamic>> _options = [
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
      'type': 'borrow_lend',
      'comingSoon': true,
    },
    {
      'icon': Icons.payment,
      'label': 'Payments',
      'type': 'payment',
      'comingSoon': true,
    },
  ];

  void _navigateToExpensesScreen(String type) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensesScreen(initialType: type),
      ),
    );
  }

  void _showComingSoon() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming Soon'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'New Transaction',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._options.map((option) {
            final isComingSoon = option['comingSoon'] == true;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isComingSoon
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFF3A7BFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option['icon'],
                  color: isComingSoon
                      ? Colors.white54
                      : const Color(0xFF3A7BFF),
                  size: 24,
                ),
              ),
              title: Text(
                option['label'],
                style: TextStyle(
                  color: isComingSoon ? Colors.white54 : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: isComingSoon
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    )
                  : null,
              onTap: () {
                if (isComingSoon) {
                  _showComingSoon();
                } else {
                  _navigateToExpensesScreen(option['type']);
                }
              },
            );
          }).toList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

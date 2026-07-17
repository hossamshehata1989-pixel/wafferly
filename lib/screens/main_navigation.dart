// lib/screens/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:wafferly/features/analysis/screens/analysis_screen.dart';
import '../l10n/app_localizations.dart';
import 'accounts/accounts_screen.dart';
import 'expenses_screen.dart';
import 'transactions/transactions_screen.dart';
import 'planning/planning_screen.dart';
import '../constants/transaction_constants.dart';
import '../features/members/screens/members_screen.dart';
import 'package:wafferly/features/settings/presentation/screens/settings_screen.dart';
import 'manage/manage_screen.dart';
import 'package:wafferly/features/financial_action_center/financial_action_center.dart';
import '../widgets/notifications/wafferly_toast.dart';
import '../widgets/common/expense_toast_layer.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _showMoreMenu = false;
  bool _showFinancialActions = true;

  final List<Widget> _pages = const [
    AccountsScreen(),
    TransactionsScreen(),
    PlanningScreen(),
    ManageScreen(),
    AnalysisScreen(),
    SizedBox(),
  ];

  void _onItemTapped(int index) {
    if (index == 5) {
      setState(() {
        _showMoreMenu = !_showMoreMenu;
      });
      return;
    }
    setState(() {
      _showMoreMenu = false;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        IgnorePointer(
          ignoring: _showFinancialActions,
          child: Scaffold(
            body: Stack(
              children: [
                _pages[_selectedIndex],
                if (_showMoreMenu)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showMoreMenu = false;
                      });
                    },
                    child: Container(color: Colors.black54),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0,
                  bottom: 0,
                  right: _showMoreMenu ? 0 : -320,
                  child: const _MoreDrawer(),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF3A7BFF),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              showUnselectedLabels: true,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.account_balance_wallet),
                  label: t.accounts,
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: 'Transactions',
                ),

                const BottomNavigationBarItem(
                  icon: Icon(Icons.flag_outlined),
                  activeIcon: Icon(Icons.flag),
                  label: 'Planning',
                ),

                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  activeIcon: Icon(Icons.dashboard_customize),
                  label: 'Manage',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  activeIcon: Icon(Icons.analytics),
                  label: 'Analysis',
                ),
                BottomNavigationBarItem(
                  icon: Icon(_showMoreMenu ? Icons.close : Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: "mainNavigationFab",
              onPressed: _showAddBottomSheet,
              backgroundColor: const Color(0xFF3A7BFF),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        ),

        // Modal Barrier
        if (_showFinancialActions)
          Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: isDark
                  ? Colors.black.withOpacity(0.75)
                  : Colors.black.withOpacity(0.45),
            ),
          ),

        // Financial Action Center Sheet
        if (_showFinancialActions)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.height * 0.06,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color.fromARGB(255, 0, 42, 254),
                            const Color.fromARGB(255, 64, 214, 9),
                            const Color.fromARGB(255, 247, 23, 7),
                          ]
                        : [
                            Colors.grey.shade50,
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.shade300.withOpacity(0.4),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.5)
                          : Colors.grey.shade600.withOpacity(0.15),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.shade300.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: FinancialActionCenter(
                    onSkip: () {
                      setState(() {
                        _showFinancialActions = false;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        const ExpenseToastLayer(),
      ],
    );
  }
}

// =====================================
// MORE DRAWER - مع expandable sections
// =====================================

class _MoreDrawer extends StatefulWidget {
  const _MoreDrawer();

  @override
  State<_MoreDrawer> createState() => _MoreDrawerState();
}

class _MoreDrawerState extends State<_MoreDrawer> {
  final Map<String, bool> _expandedSections = {
    '💰 Financial': true,
    '🎉 Life & Events': false,
    '🔔 Automation': false,
    '🤖 AI Tools': false,
    '👥 Family': false,
    '☁ Sync': false,
  };

  final Map<String, List<Map<String, dynamic>>> _sections = {
    '💰 Financial': [
      {
        'icon': Icons.trending_up,
        'label': 'Investments',
        'color': Colors.green,
      },
      {'icon': Icons.money_off, 'label': 'Debts', 'color': Colors.red},
      {'icon': Icons.group, 'label': 'Rosca', 'color': Colors.orange},
      {
        'icon': Icons.calendar_month,
        'label': 'Installments',
        'color': Colors.purple,
      },
    ],
    '🎉 Life & Events': [
      {'icon': Icons.cake, 'label': 'Birthdays', 'color': Colors.pink},
      {'icon': Icons.event, 'label': 'Upcoming Events', 'color': Colors.amber},
    ],
    '🔔 Automation': [
      {
        'icon': Icons.repeat,
        'label': 'Recurring Transactions',
        'color': Colors.cyan,
      },
      {
        'icon': Icons.notifications,
        'label': 'Payment Reminders',
        'color': Colors.blue,
      },
      {'icon': Icons.alarm, 'label': 'Bill Reminders', 'color': Colors.indigo},
    ],
    '🤖 AI Tools': [
      {'icon': Icons.sms, 'label': 'SMS Import', 'color': Colors.teal},
      {
        'icon': Icons.description,
        'label': 'Import Documents',
        'color': Colors.lightBlue,
      },
      {'icon': Icons.insights, 'label': 'Insights', 'color': Colors.deepPurple},
    ],
    '👥 Family': [
      {
        'icon': Icons.account_balance_wallet,
        'label': 'Shared Wallet',
        'color': Colors.green,
      },
      {'icon': Icons.people, 'label': 'Members', 'color': Colors.blue},
    ],
    '☁ Sync': [
      {'icon': Icons.backup, 'label': 'Backup', 'color': Colors.orange},
      {'icon': Icons.file_copy, 'label': 'Export Excel', 'color': Colors.green},
      {
        'icon': Icons.picture_as_pdf,
        'label': 'Export PDF',
        'color': Colors.red,
      },
    ],
  };

  void _toggleSection(String title) {
    setState(() {
      _expandedSections[title] = !(_expandedSections[title] ?? false);
    });
  }

  void _onSubMenuItemTap(String label) {
    if (label == "Members") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MembersScreen()),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$label coming soon")));
  }

  Widget settingsTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.settings, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(0, 0, 0, 0),
      child: Container(
        width: 280,
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D111A),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          border: Border(
            left: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ..._sections.keys.map((title) {
              return _buildExpandableSection(title);
            }),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            settingsTile(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection(String title) {
    final isExpanded = _expandedSections[title] ?? false;
    final items = _sections[title] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleSection(title),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: const Color(0xFFFFC107),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFC107),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              children: items
                  .map(
                    (item) => _subMenuItem(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      color: item['color'] as Color,
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _subMenuItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSubMenuItemTap(label),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================
// ADD TRANSACTION SHEET
// =====================================

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
      'color': Colors.red,
    },
    {
      'icon': Icons.trending_up,
      'label': 'Income',
      'type': TransactionType.income,
      'color': Colors.green,
    },
    {
      'icon': Icons.swap_horiz,
      'label': 'Transfer',
      'type': TransactionType.transfer,
      'color': Colors.blue,
    },
  ];

  Future<void> _navigateToExpensesScreen(String type) async {
    Navigator.pop(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensesScreen(initialType: type),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      WafferlyToast.showSuccess(context, message: "Transaction saved");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2A),
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
          const SizedBox(height: 20),
          ..._options.map((option) {
            final iconColor = option['color'] as Color;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option['icon'], color: iconColor, size: 24),
              ),
              title: Text(
                option['label'],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () => _navigateToExpensesScreen(option['type']),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

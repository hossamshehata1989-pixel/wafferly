// lib/screens/transactions/widgets/transaction_tab_bar.dart

import 'package:flutter/material.dart';

class TransactionTabBar extends StatefulWidget {
  final ValueChanged<int> onTabChanged;
  const TransactionTabBar({super.key, required this.onTabChanged});

  @override
  State<TransactionTabBar> createState() => _TransactionTabBarState();
}

class _TransactionTabBarState extends State<TransactionTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _tabs = const [
    {'icon': Icons.receipt_long, 'label': 'Expenses', 'type': 'expense'},
    {'icon': Icons.trending_up, 'label': 'Income', 'type': 'income'},
    {'icon': Icons.swap_horiz, 'label': 'Transfers', 'type': 'transfer'},
    {'icon': Icons.handshake, 'label': 'Borrow/Lend', 'type': 'borrowLend'},
    {'icon': Icons.payment, 'label': 'Payments', 'type': 'payment'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _currentIndex != _tabController.index) {
        _currentIndex = _tabController.index;
        widget.onTabChanged(_currentIndex);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: const Color(0xFF3A7BFF),
          borderRadius: BorderRadius.circular(30),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _currentIndex == index;
          return Tab(
            icon: Icon(tab['icon'], size: 22),
            text: isSelected ? tab['label'] : null,
          );
        }).toList(),
      ),
    );
  }
}

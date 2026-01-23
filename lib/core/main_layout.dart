/*
========================================
File: main_layout.dart
Purpose: App main layout with BottomNav
Project: Wafferly
STEP: 2
========================================
*/

import 'package:flutter/material.dart';
import '../screens/expenses_screen.dart';

// ================================
// STEP 2: Main Layout
// ================================
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // STEP 2.1: Pages
  final List<Widget> _pages = const [
    ExpensesScreen(),
    Center(child: Text('Income (Later)')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      // STEP 2.2: Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Income',
          ),
        ],
      ),
    );
  }
}

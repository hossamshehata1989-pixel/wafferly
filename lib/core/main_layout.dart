/*
========================================
File: main_layout.dart
Purpose: App main layout with BottomNav
Project: Wafferly
STEP: FIXED
========================================
*/

import 'package:flutter/material.dart';
import 'package:wafferly/l10n/app_localizations.dart';
import '../screens/expenses_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {

  // ---------------------------------------------------
  // 📌 Current Tab Index
  // ---------------------------------------------------
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Scaffold(

      // ---------------------------------------------------
      // 🧠 Screens (IndexedStack علشان يحافظ على الحالة)
      // ---------------------------------------------------
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ExpensesScreen(),
          Placeholder(), // Income (later)
        ],
      ),

      // ---------------------------------------------------
      // 🔽 Bottom Navigation
      // ---------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black54,

        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: t.expenses,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: t.income,
          ),
        ],
      ),
    );
  }
}
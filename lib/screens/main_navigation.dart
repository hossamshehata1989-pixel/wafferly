import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

import 'accounts/accounts_screen.dart';
import 'expenses_screen.dart';
import '../features/analysis/screens/analysis_screen.dart';
import 'planning/planning_screen.dart';

// 🟡 Placeholder مؤقت لحد ما تعمل Settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Settings"));
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  // ✅ نفس عدد الأيقونات بالظبط
  final pages = const [
    AccountsScreen(),
    ExpensesScreen(),
    AnalysisScreen(),
    PlanningScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inactive,
        showUnselectedLabels: true,

        onTap: (i) {
          setState(() {
            index = i;
          });
        },

        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: AppLocalizations.of(context)!.accounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: AppLocalizations.of(context)!.expenses,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: AppLocalizations.of(context)!.analysis,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            label: AppLocalizations.of(context)!.planning,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
    );
  }
}

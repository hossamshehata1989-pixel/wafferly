import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'expenses_screen.dart';
import '../features/analysis/screens/analysis_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int index = 0;

  final pages = [
      const AnalysisScreen(),   // 👈 الرئيسية
      const ExpensesScreen(),   // 👈 المصروفات
      const Center(child: Text("Statistics Screen")), // مؤقت
      const Center(child: Text("Settings Screen")),   // مؤقت
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

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "الرئيسية",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.money_off),
            label: "المصروفات",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "الاحصائيات",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "الاعدادات",
          ),

        ],

      ),

    );

  }

}
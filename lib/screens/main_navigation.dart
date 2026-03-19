import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'expenses_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int index = 0;

  final pages = [
    const ExpensesScreen(),
    const ExpensesScreen(),
    const ExpensesScreen(),
    const ExpensesScreen(),
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
            icon: Icon(Icons.home),
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
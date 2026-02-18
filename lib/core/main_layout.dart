/*
========================================
File: main_layout.dart
Purpose: App main layout with BottomNav
Project: Wafferly
STEP: 2
========================================
*/

import 'package:flutter/material.dart';
import 'package:wafferly/l10n/app_localizations.dart';
import '../screens/expenses_screen.dart';

class MainLayout extends StatefulWidget {           // 🔴 StatefulWidget لتمكين التنقل بين الشاشات
  const MainLayout({super.key});    // 🔴 لا حاجة لتمرير بيانات في الوقت الحالي، لكن يمكنك إضافة خصائص إذا أردت

  @override
  State<MainLayout> createState() => _MainLayoutState();  // 🔴 إنشاء الحالة المرتبطة بهذا الـ StatefulWidget
}

class _MainLayoutState extends State<MainLayout> {    // 🔴 حالة MainLayout لإدارة التنقل بين الشاشات
  int _currentIndex = 0;      // 🔴 المتغير لتتبع الشاشة الحالية (0: Expenses, 1: Income)

  @override
  Widget build(BuildContext context) {    // 🔴 بناء واجهة المستخدم
    final t = AppLocalizations.of(context)!;          // 🔴 الحصول على النصوص المترجمة لاستخدامها في الـ BottomNavigationBar

    return Scaffold(       // 🔴 Scaffold لتوفير الهيكل الأساسي للتطبيق
      body: IndexedStack(         // 🔴 IndexedStack لعرض الشاشة الحالية بناءً على _currentIndex
        index: _currentIndex,        // 🔴 قائمة الشاشات التي يمكن التنقل بينها
        children: const [        // 🔴 يمكنك إضافة المزيد من الشاشات هنا إذا أردت
          ExpensesScreen(),            // 🔴 شاشة النفقات
          Placeholder(), // Income later    // 🔴 شاشة الدخل (يمكنك استبدالها بشاشة فعلية لاحقًا)
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(      // 🔴 شريط التنقل السفلي
        type: BottomNavigationBarType.fixed,        // 🔴 نوع شريط التنقل (ثابت لعرض جميع العناصر)
         backgroundColor: Colors.white,        // 🔴 لون خلفية شريط التنقل
         selectedItemColor: Colors.blue,       // 🔴 لون العنصر المحدد
         unselectedItemColor: Colors.black54,  // 🔴 لون العناصر غير المحددة
         currentIndex: _currentIndex,          // 🔴 تحديد العنصر الحالي بناءً على _currentIndex
        currentIndex: _currentIndex,    // 🔴 تحديد العنصر الحالي بناءً على _currentIndex
         onTap: (index) {        // 🔴 عند النقر على عنصر في شريط التنقل
          setState(() {            // 🔴 تحديث الحالة لتغيير الشاشة المعروضة
            _currentIndex = index;       // 🔴 تحديث _currentIndex إلى العنصر الذي تم النقر عليه
          });
        },
        onTap: (index) {     // 🔴 عند النقر على عنصر في شريط التنقل
          setState(() {          // 🔴 تحديث الحالة لتغيير الشاشة المعروضة
            _currentIndex = index;     // 🔴 تحديث _currentIndex إلى العنصر الذي تم النقر عليه
          });
        },
        items: [         // 🔴 عناصر شريط التنقل مع الأيقونات والنصوص المترجمة
          BottomNavigationBarItem(          // 🔴 عنصر النفقات
            icon: const Icon(Icons.receipt_long),   // 🔴 أيقونة النفقات
            label: t.expenses,          // 🔴 نص النفقات
          ),
          BottomNavigationBarItem(      // 🔴 عنصر الدخل
            icon: const Icon(Icons.account_balance_wallet),       // 🔴 أيقونة الدخل
            label: t.income,          // 🔴 نص الدخل
          ),
        ],
      ),
    );
  }
}

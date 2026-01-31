import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 👈 إضافة
import 'screens/expenses_screen.dart';
import 'l10n/app_localizations.dart'; // 👈 إضافة

void main() {
  runApp(const WafferlyApp());
}

class WafferlyApp extends StatelessWidget {
  const WafferlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wafferly',

      // 🌍 تفعيل الترجمة
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      home: const ExpensesScreen(),
    );
  }
}

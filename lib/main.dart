import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/expenses_screen.dart';
import 'l10n/app_localizations.dart';

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
        primaryColor: const Color(0xFF3A7BFF),

        scaffoldBackgroundColor: const Color(0xFF0F1B4C),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1B4C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      home: const ExpensesScreen(),
    );
  }
}
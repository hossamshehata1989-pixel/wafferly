/*
========================================
File: main.dart
Purpose: App entry point & root widget
Project: Wafferly
========================================
*/
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wafferly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'core/main_layout.dart';


void main() {
  runApp(const WafferlyApp());
}

// ================================
// STEP 1: Root App Widget
// ================================
class WafferlyApp extends StatelessWidget {
  const WafferlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,

  // 🌍 Localization Setup
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

  locale: const Locale('ar'), // العربي افتراضي

  theme: ThemeData(
    useMaterial3: false,
    primarySwatch: Colors.green,
  ),

  home: MainLayout(),
);

  }
}

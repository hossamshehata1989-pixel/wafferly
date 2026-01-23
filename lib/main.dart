/*
========================================
File: main.dart
Purpose: App entry point & root widget
Project: Wafferly
========================================
*/

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
      title: 'Wafferly',
      debugShowCheckedModeBanner: false,

      // STEP 1.1: App Theme
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.green,
      ),

      // STEP 1.2: App Entry Layout
      home: MainLayout(),
    );
  }
}

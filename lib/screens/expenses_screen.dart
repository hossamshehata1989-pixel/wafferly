/*
========================================
File: expenses_screen.dart
Purpose: Main expenses screen (Add & view expenses)
Project: Wafferly
STEP: 3
========================================
*/

import 'package:flutter/material.dart';

// ================================
// STEP 3: Expenses Screen
// ================================
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // STEP 3.1: AppBar
      appBar: AppBar(
        title: const Text('Expenses'),
        centerTitle: true,
      ),

      // STEP 3.2: Screen Body (Temporary Content)
      body: const Center(
        child: Text(
          'Expenses Screen',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

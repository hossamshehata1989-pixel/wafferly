// ==========================================
// 📊 ANALYSIS SCREEN (UPDATED)
// ==========================================

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/expense.dart';
import '../logic/analysis_calculator.dart';
import '../widgets/custom_donut_chart.dart';
import '../widgets/category_panel.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Expense>('expenses');

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text("Analysis"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, Box<Expense> box, __) {
          final expenses = box.values.toList();
          final result = calculateAnalysis(expenses);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _card("Total", result.total),
                    _card("Normal", result.normal),
                    _card("Exceptional", result.exceptional),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDonutChart(
                      data: _prepareDonutData(result.totalCategories),
                      baseColor: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CategoryPanel(
                        title: "Total Expenses",
                        data: result.totalCategories,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDonutChart(
                      data: _prepareDonutData(result.normalCategories),
                      baseColor: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CategoryPanel(
                        title: "Normal Expenses",
                        data: result.normalCategories,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

List<DonutData> _prepareDonutData(Map<String, double> data) {
  final sorted = data.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.length <= 4) {
    return sorted.map((e) => DonutData(e.key, e.value)).toList();
  }

  final top4 = sorted.take(4).toList();
  final others = sorted.skip(4);
  final otherSum = others.fold(0.0, (sum, e) => sum + e.value);
  final result = [...top4, MapEntry("Other", otherSum)];
  
  return result.map((e) => DonutData(e.key, e.value)).toList();
}

Widget _card(String title, double value) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 6),
          Text(
            "${value.toInt()} EGP",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
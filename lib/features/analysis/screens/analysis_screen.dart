import 'package:flutter/material.dart';
import '../widgets/custom_donut_chart.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int insightIndex = 0;

  final insights = [
    "You spend more on one-time expenses",
    "Your recurring expenses are stable",
    "Food is your top category",
  ];

  @override
  void initState() {
    super.initState();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;

      setState(() {
        insightIndex = (insightIndex + 1) % insights.length;
      });

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),

      appBar: AppBar(
        title: const Text("Analysis"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // cards
            Row(
              children: [
                _card("Total", 10000),
                _card("Recurring", 4000),
                _card("One-time", 6000),
              ],
            ),

            const SizedBox(height: 30),

            // charts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    CustomDonutChart(
                      data: [
                        DonutData("Food", 1500),
                        DonutData("Transport", 800),
                        DonutData("Bills", 700),
                      ],
                      baseColor: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    const Text("Recurring",
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
                Column(
                  children: [
                    CustomDonutChart(
                      data: [
                        DonutData("Shopping", 2000),
                        DonutData("Health", 1500),
                        DonutData("Repair", 1000),
                      ],
                      baseColor: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    const Text("One-time",
                        style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // animated insight
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(insights[insightIndex]),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.4),
                      Colors.orange.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb,
                        color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insights[insightIndex],
                        style:
                            const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// card
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
          Text("$value EGP",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}
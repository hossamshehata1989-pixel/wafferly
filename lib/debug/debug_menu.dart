import 'package:flutter/material.dart';

import '../features/financial_action_center/financial_action_center.dart';

class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wafferly Debug Menu')),
      body: ListView(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FinancialActionCenter(onSkip: () {}),
                  ),
                );
              },
              child: const Text("OPEN"),
            ),
          ),
        ],
      ),
    );
  }
}

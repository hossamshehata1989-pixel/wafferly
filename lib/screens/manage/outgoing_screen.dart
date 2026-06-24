import 'package:flutter/material.dart';
import 'debts_screen.dart';

class OutgoingScreen extends StatelessWidget {
  const OutgoingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outgoing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.red),
              title: const Text('Debts'),
              subtitle: const Text(
                'Credit Cards, Loans, Installments, Borrowed Money',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebtsScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.repeat, color: Colors.orange),
              title: const Text('Recurring Expenses'),
              subtitle: const Text('Must, Need, Want'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

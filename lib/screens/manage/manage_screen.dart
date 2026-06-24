import 'package:flutter/material.dart';
import 'outgoing_screen.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Commitments',
            children: [
              _MenuTile(
                icon: Icons.arrow_upward,
                title: 'Outgoing',
                subtitle: 'Debts & Recurring Expenses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OutgoingScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              const _MenuTile(
                icon: Icons.arrow_downward,
                title: 'Incoming',
                subtitle: 'Scheduled Income',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Planning',
            children: [
              _MenuTile(
                icon: Icons.flag,
                title: 'Goals',
                subtitle: 'Savings Goals',
              ),
              Divider(height: 1),
              _MenuTile(
                icon: Icons.account_balance_wallet,
                title: 'Budgets',
                subtitle: 'Spending Plans',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';

import 'widgets/developer_action_card.dart';
import 'development_data_seeder.dart';

class DeveloperToolsPage extends StatelessWidget {
  const DeveloperToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: ListView(
        children: [
          DeveloperActionCard(
            icon: Icons.grass,
            title: 'Seed Financial Demo',
            subtitle: 'Create demo accounts and financial data',
            onTap: () async {
              debugPrint('🌱 Seed button pressed');

              await DevelopmentDataSeeder.seedFinancialDemo();

              debugPrint('✅ Seed completed');

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Financial demo seeded')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../models/enums/account_enums.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = AccountService().getAllActiveAccounts();

    final liabilityAccounts = accounts
        .where((a) => a.group == AccountGroup.liabilities)
        .toList();

    final creditCards = liabilityAccounts
        .where((a) => a.type == 'creditCard')
        .toList();

    final loans = liabilityAccounts.where((a) => a.type == 'loan').toList();

    final installments = liabilityAccounts
        .where((a) => a.type == 'installment')
        .toList();

    final borrowedMoney = liabilityAccounts
        .where((a) => a.type == 'debt' || a.type == 'moneyBorrowed')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Debts')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO:
          // Open AddAccountScreen(sectionType: liability)
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DebtSection(
            title: 'Credit Cards',
            icon: Icons.credit_card,
            accounts: creditCards,
          ),

          const SizedBox(height: 16),

          _DebtSection(
            title: 'Loans',
            icon: Icons.account_balance,
            accounts: loans,
          ),

          const SizedBox(height: 16),

          _DebtSection(
            title: 'Borrowed Money',
            icon: Icons.people,
            accounts: borrowedMoney,
          ),

          const SizedBox(height: 16),

          _DebtSection(
            title: 'Installments',
            icon: Icons.calendar_month,
            accounts: installments,
          ),
        ],
      ),
    );
  }
}

class _DebtSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Account> accounts;

  const _DebtSection({
    required this.title,
    required this.icon,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  accounts.length.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No accounts yet'),
              ),

            ...accounts.map(
              (account) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(account.name),
                subtitle: Text(account.type),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO:
                  // Debt Details Screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

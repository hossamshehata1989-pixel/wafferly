import 'package:flutter/material.dart';

import '../../services/account_service.dart';

class AccountDetailsScreen extends StatelessWidget {
  final String accountId;

  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final account = AccountService().getAccountById(accountId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Details')),
        body: const Center(child: Text('Account not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            title: 'General',
            children: [
              _InfoRow(label: 'Name', value: account.name),
              _InfoRow(label: 'Type', value: account.type),
              _InfoRow(label: 'Currency', value: account.currency),
            ],
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: 'Classification',
            children: [
              _InfoRow(label: 'Group', value: account.group.name),
              _InfoRow(label: 'Nature', value: account.nature.name),
            ],
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: 'Additional Information',
            children: [
              _InfoRow(label: 'Provider', value: account.provider ?? '-'),
              _InfoRow(
                label: 'Account Number',
                value: account.accountNumber ?? '-',
              ),
              _InfoRow(label: 'Created', value: account.createdAt.toString()),
            ],
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: 'Notes',
            children: [
              Text(
                account.notes?.isNotEmpty == true ? account.notes! : 'No notes',
              ),
            ],
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              // TODO:
              // Edit Account Screen
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Account'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Archive Account'),
                    content: const Text(
                      'Are you sure you want to archive this account?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Archive'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                await AccountService().archiveAccount(account.id);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive Account'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

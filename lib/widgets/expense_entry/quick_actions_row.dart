// lib/widgets/expense_entry/quick_actions_row.dart

import 'package:flutter/material.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class QuickActionsRow extends StatelessWidget {
  final TransactionEntryController controller;

  const QuickActionsRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildQuickButton(
            icon: Icons.account_balance_wallet,
            label: controller.selectedAccountName,
            onTap: () => _showAccountPicker(context),
          ),
          const SizedBox(width: 8),
          _buildQuickButton(
            icon: Icons.calendar_today,
            label: _getDateLabel(context),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(width: 8),
          _buildQuickButton(
            icon: Icons.people,
            label: t.members,
            onTap: () => _showMembersMessage(context, t),
            isDisabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isDisabled ? Colors.white38 : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? Colors.white38 : Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateLabel(BuildContext context) {
    final today = DateTime.now();
    final selected = controller.selectedDate;

    if (selected.year == today.year &&
        selected.month == today.month &&
        selected.day == today.day) {
      return AppLocalizations.of(context)!.today;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (selected.year == yesterday.year &&
        selected.month == yesterday.month &&
        selected.day == yesterday.day) {
      return AppLocalizations.of(context)!.yesterday;
    }

    return "${selected.day}/${selected.month}";
  }

  void _showAccountPicker(BuildContext context) {
    final accounts = controller.availableAccounts;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noAccountsAvailable),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.selectAccount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: accounts
                    .map(
                      (acc) => ListTile(
                        leading: Icon(
                          _getAccountIcon(acc.type),
                          color: _getAccountColor(acc.type),
                        ),
                        title: Text(
                          acc.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          acc.type,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          controller.selectAccount(acc.id, acc.name);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3A7BFF),
            surface: Color(0xFF1B2A6B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.setSelectedDate(picked);
  }

  void _showMembersMessage(BuildContext context, AppLocalizations t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.membersFeatureComingSoon),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      case 'debt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.attach_money;
      case 'bank':
        return Icons.account_balance;
      case 'debt':
        return Icons.receipt_long;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

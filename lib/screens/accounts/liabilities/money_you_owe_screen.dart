import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/account.dart';
import '../../../models/enums/account_enums.dart';
import '../../../models/enums/section_type.dart';
import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';
import '../navigation/accounts_navigator.dart';
import '../add_account/add_account_screen.dart';

class MoneyYouOweScreen extends StatelessWidget {
  const MoneyYouOweScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountService = AccountService();
    final balanceService = BalanceService();

    return Scaffold(
      backgroundColor: const Color(0xFF031722),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Money You Owe', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ValueListenableBuilder(
        valueListenable: accountService.box.listenable(),
        builder: (context, Box<Account> _, __) {
          final accounts = accountService.getAllActiveAccounts()
              .where((a) => a.group == AccountGroup.liabilities)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              const Text('Manage each type of liability separately.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              _LiabilityCategoryCard(
                title: 'Credit Cards',
                subtitle: 'Cards, limits, statements and purchases',
                icon: Icons.credit_card_rounded,
                accent: const Color(0xFFFF3D81),
                accounts: accounts.where((a) => a.type == 'creditCard').toList(),
                balanceService: balanceService,
                emptyLabel: 'No credit cards yet',
                onTap: () => AccountsNavigator.showLiabilityCategory(context: context, category: LiabilityCategory.creditCards),
              ),
              const SizedBox(height: 12),
              _LiabilityCategoryCard(
                title: 'Loans',
                subtitle: 'Loan principal, payments and due dates',
                icon: Icons.account_balance_rounded,
                accent: const Color(0xFF4D9CFF),
                accounts: accounts.where((a) => a.type == 'loan').toList(),
                balanceService: balanceService,
                emptyLabel: 'No loans yet',
                onTap: () => AccountsNavigator.showLiabilityCategory(context: context, category: LiabilityCategory.loans),
              ),
              const SizedBox(height: 12),
              _LiabilityCategoryCard(
                title: 'Installments / BNPL',
                subtitle: 'Installment plans and buy-now-pay-later',
                icon: Icons.calendar_month_rounded,
                accent: const Color(0xFFFFA52F),
                accounts: accounts.where((a) => a.type == 'installment' || a.type == 'bnpl').toList(),
                balanceService: balanceService,
                emptyLabel: 'No installment plans yet',
                onTap: () => AccountsNavigator.showLiabilityCategory(context: context, category: LiabilityCategory.installments),
              ),
              const SizedBox(height: 12),
              _LiabilityCategoryCard(
                title: 'Borrowed Money',
                subtitle: 'Money borrowed from people or other sources',
                icon: Icons.person_rounded,
                accent: const Color(0xFF7C72FF),
                accounts: accounts.where((a) => a.type == 'debt' || a.type == 'moneyBorrowed').toList(),
                balanceService: balanceService,
                emptyLabel: 'No borrowed money yet',
                onTap: () => AccountsNavigator.showLiabilityCategory(context: context, category: LiabilityCategory.borrowedMoney),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAccountScreen(sectionType: SectionType.liabilities)),
                ),
                child: const Text('Add Other Liability'),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum LiabilityCategory { creditCards, loans, installments, borrowedMoney }

class _LiabilityCategoryCard extends StatelessWidget {
  const _LiabilityCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accounts,
    required this.balanceService,
    required this.emptyLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Account> accounts;
  final BalanceService balanceService;
  final String emptyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = accounts.fold<double>(
      0,
      (sum, account) => sum + (-balanceService.getBalance(account.id)).clamp(0, double.infinity).toDouble(),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1C2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: .32)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(accounts.isEmpty ? emptyLabel : '${accounts.length} account${accounts.length == 1 ? '' : 's'}', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${total.toStringAsFixed(0)} EGP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

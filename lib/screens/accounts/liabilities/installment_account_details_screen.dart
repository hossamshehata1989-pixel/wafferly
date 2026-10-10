import 'package:flutter/material.dart';

import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';
import 'liability_detail_widgets.dart';

class InstallmentAccountDetailsScreen extends StatelessWidget {
  const InstallmentAccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final account = AccountService().getAccountById(accountId);
    if (account == null) {
      return const Scaffold(body: Center(child: Text('Installment plan not found')));
    }

    final outstanding = (-BalanceService().getBalance(accountId))
        .clamp(0, double.infinity)
        .toDouble();

    return LiabilityDetailScaffold(
      title: 'Installment / BNPL',
      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded))],
      children: [
        LiabilityIdentityCard(
          name: account.name,
          typeLabel: 'Installment / BNPL',
          currency: account.currency,
          icon: Icons.calendar_month_rounded,
          accent: const Color(0xFFFFA52F),
          secondaryLabel: account.provider,
        ),
        const SizedBox(height: 14),
        LiabilityOutstandingCard(
          outstanding: outstanding,
          currency: account.currency,
          accent: const Color(0xFFFFA52F),
        ),
        const SizedBox(height: 14),
        const LiabilitySectionCard(
          title: 'Plan Details',
          subtitle: 'Purchase, principal, installment amount and financing terms will appear here when configured.',
          icon: Icons.shopping_bag_outlined,
        ),
        const SizedBox(height: 10),
        const LiabilitySectionCard(
          title: 'Next Installment',
          subtitle: 'The next scheduled installment will appear here.',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 10),
        const LiabilitySectionCard(
          title: 'Installment Schedule',
          subtitle: 'Upcoming and settled installments will appear here.',
          icon: Icons.event_repeat_rounded,
        ),
        const SizedBox(height: 10),
        LiabilitySectionCard(
          title: 'Transactions',
          subtitle: 'View the financial transactions linked to this liability account.',
          icon: Icons.receipt_long_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}

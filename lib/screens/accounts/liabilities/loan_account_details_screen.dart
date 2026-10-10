import 'package:flutter/material.dart';

import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';
import 'liability_detail_widgets.dart';

class LoanAccountDetailsScreen extends StatelessWidget {
  const LoanAccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final account = AccountService().getAccountById(accountId);
    if (account == null) {
      return const Scaffold(body: Center(child: Text('Loan not found')));
    }

    final outstanding = (-BalanceService().getBalance(accountId))
        .clamp(0, double.infinity)
        .toDouble();

    return LiabilityDetailScaffold(
      title: 'Loan',
      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded))],
      children: [
        LiabilityIdentityCard(
          name: account.name,
          typeLabel: 'Loan',
          currency: account.currency,
          icon: Icons.account_balance_rounded,
          accent: const Color(0xFF4D9CFF),
          secondaryLabel: account.provider,
        ),
        const SizedBox(height: 14),
        LiabilityOutstandingCard(
          outstanding: outstanding,
          currency: account.currency,
          accent: const Color(0xFF4D9CFF),
        ),
        const SizedBox(height: 14),
        const LiabilitySectionCard(
          title: 'Loan Terms',
          subtitle: 'Principal, interest and repayment terms will appear here when configured.',
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: 10),
        const LiabilitySectionCard(
          title: 'Next Payment',
          subtitle: 'No payment schedule is configured for this loan yet.',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 10),
        const LiabilitySectionCard(
          title: 'Repayment Schedule',
          subtitle: 'Scheduled loan obligations will appear here.',
          icon: Icons.event_outlined,
        ),
        const SizedBox(height: 10),
        LiabilitySectionCard(
          title: 'Transactions',
          subtitle: 'View the financial transactions linked to this loan account.',
          icon: Icons.receipt_long_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';
import 'liability_detail_widgets.dart';

class BorrowedMoneyAccountDetailsScreen extends StatelessWidget {
  const BorrowedMoneyAccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final account = AccountService().getAccountById(accountId);
    if (account == null) {
      return const Scaffold(body: Center(child: Text('Borrowed money account not found')));
    }

    final outstanding = (-BalanceService().getBalance(accountId))
        .clamp(0, double.infinity)
        .toDouble();

    return LiabilityDetailScaffold(
      title: 'Borrowed Money',
      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded))],
      children: [
        LiabilityIdentityCard(
          name: account.name,
          typeLabel: 'Borrowed Money',
          currency: account.currency,
          icon: Icons.person_rounded,
          accent: const Color(0xFF7C72FF),
          secondaryLabel: account.provider,
        ),
        const SizedBox(height: 14),
        LiabilityOutstandingCard(
          outstanding: outstanding,
          currency: account.currency,
          accent: const Color(0xFF7C72FF),
        ),
        const SizedBox(height: 14),
        LiabilitySectionCard(
          title: 'Borrowing Details',
          subtitle: account.provider?.isNotEmpty == true
              ? 'Borrowed from ${account.provider}. Additional terms can be configured later.'
              : 'Lender/source and borrowing terms are not configured yet.',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 10),
        const LiabilitySectionCard(
          title: 'Repayment Plan',
          subtitle: 'Expected repayment date and agreed terms will appear here when configured.',
          icon: Icons.event_outlined,
        ),
        const SizedBox(height: 10),
        const LiabilitySectionCard(
          title: 'Repayment History',
          subtitle: 'Repayments against this liability will appear here.',
          icon: Icons.history_rounded,
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

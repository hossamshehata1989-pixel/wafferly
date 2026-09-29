import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';

class LiabilityAccountDetailsScreen extends StatelessWidget {
  const LiabilityAccountDetailsScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final account = AccountService().getAccountById(accountId);
    if (account == null) return const Scaffold(body: Center(child: Text('Liability not found')));
    final outstanding = (-BalanceService().getBalance(accountId)).clamp(0, double.infinity).toDouble();
    final spec = _spec(account.type);

    return Scaffold(
      backgroundColor: const Color(0xFF020D16),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white), title: Text(spec.title, style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF0A1C29), borderRadius: BorderRadius.circular(20), border: Border.all(color: spec.accent.withValues(alpha: .32))),
            child: Row(children: [
              Container(width: 58, height: 58, decoration: BoxDecoration(color: spec.accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: Icon(spec.icon, color: spec.accent, size: 30)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(account.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text('${spec.title} • ${account.currency}', style: const TextStyle(color: Colors.white54, fontSize: 12))])),
            ]),
          ),
          const SizedBox(height: 14),
          _MetricPanel(spec: spec, outstanding: outstanding, currency: account.currency),
          const SizedBox(height: 14),
          _InfoCard(title: spec.primaryTitle, subtitle: spec.primarySubtitle, icon: spec.icon),
          const SizedBox(height: 10),
          _InfoCard(title: 'Payments', subtitle: spec.paymentSubtitle, icon: Icons.payments_outlined),
          const SizedBox(height: 10),
          _InfoCard(title: 'Schedule', subtitle: spec.scheduleSubtitle, icon: Icons.event_outlined),
        ],
      ),
    );
  }

  _LiabilitySpec _spec(String type) {
    switch (type) {
      case 'loan':
        return _LiabilitySpec('Loan', 'Original principal, remaining balance and repayment schedule', Icons.account_balance_rounded, const Color(0xFF4D9CFF), 'Loan Terms', 'Principal and financing terms will appear here.', 'Payment allocation will appear here.', 'Next due date and repayment schedule will appear here.');
      case 'installment':
      case 'bnpl':
        return _LiabilitySpec('Installment / BNPL', 'Installment plan, remaining obligations and due dates', Icons.calendar_month_rounded, const Color(0xFFFFA52F), 'Plan Details', 'Provider, principal and installment terms will appear here.', 'Installment payments will appear here.', 'Installment schedule will appear here.');
      default:
        return _LiabilitySpec('Borrowed Money', 'Person/source, borrowed amount and repayment status', Icons.person_rounded, const Color(0xFF7C72FF), 'Borrowing Details', 'Lender/source and borrowing terms will appear here.', 'Repayments will appear here.', 'Agreed repayment dates will appear here.');
    }
  }
}

class _LiabilitySpec {
  const _LiabilitySpec(this.title, this.subtitle, this.icon, this.accent, this.primaryTitle, this.primarySubtitle, this.paymentSubtitle, this.scheduleSubtitle);
  final String title, subtitle, primaryTitle, primarySubtitle, paymentSubtitle, scheduleSubtitle;
  final IconData icon;
  final Color accent;
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.spec, required this.outstanding, required this.currency});
  final _LiabilitySpec spec;
  final double outstanding;
  final String currency;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFF0A1C29), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .07))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Outstanding', style: TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 6), Text('${outstanding.toStringAsFixed(2)} $currency', style: TextStyle(color: spec.accent, fontSize: 25, fontWeight: FontWeight.w800))]),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle, required this.icon});
  final String title, subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF0A1C29), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .07))), child: Row(children: [Icon(icon, color: Colors.white70), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))]))]));
}

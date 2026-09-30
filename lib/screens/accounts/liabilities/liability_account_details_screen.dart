import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/account.dart';
import '../../../services/liability_read_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';

class LiabilityAccountDetailsScreen extends StatelessWidget {
  const LiabilityAccountDetailsScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final service = LiabilityReadService();
    final account = service.getAccount(accountId);
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    if (account == null || account.isArchived) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text(t.liabilityNotFound)),
      );
    }

    final outstanding = service.outstandingFor(accountId);
    final spec = _spec(t, account.type);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          spec.title,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: m.typography.title),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          m.spacing(16),
          m.spacing(8),
          m.spacing(16),
          m.spacing(28),
        ),
        children: [
          _IdentityCard(account: account, spec: spec),
          SizedBox(height: m.space.md),
          _MetricPanel(spec: spec, outstanding: outstanding),
          SizedBox(height: m.space.md),
          _InfoCard(title: spec.primaryTitle, subtitle: spec.primarySubtitle, icon: spec.icon),
          SizedBox(height: m.space.sm),
          _InfoCard(title: t.payments, subtitle: spec.paymentSubtitle, icon: Icons.payments_outlined),
          SizedBox(height: m.space.sm),
          _InfoCard(title: t.schedule, subtitle: spec.scheduleSubtitle, icon: Icons.event_outlined),
        ],
      ),
    );
  }

  _LiabilitySpec _spec(AppLocalizations t, String type) {
    switch (type) {
      case 'loan':
        return _LiabilitySpec(
          title: t.loan,
          subtitle: t.loansSubtitle,
          icon: Icons.account_balance_rounded,
          accent: const Color(0xFF4D9CFF),
          primaryTitle: t.loanTerms,
          primarySubtitle: t.loanTermsSubtitle,
          paymentSubtitle: t.loanPaymentsSubtitle,
          scheduleSubtitle: t.loanScheduleSubtitle,
        );
      case 'installment':
      case 'bnpl':
        return _LiabilitySpec(
          title: t.installmentsBnpl,
          subtitle: t.installmentsBnplSubtitle,
          icon: Icons.calendar_month_rounded,
          accent: const Color(0xFFFFA52F),
          primaryTitle: t.planDetails,
          primarySubtitle: t.installmentPlanSubtitle,
          paymentSubtitle: t.installmentPaymentsSubtitle,
          scheduleSubtitle: t.installmentScheduleSubtitle,
        );
      default:
        return _LiabilitySpec(
          title: t.borrowedMoney,
          subtitle: t.borrowedMoneySubtitle,
          icon: Icons.person_rounded,
          accent: const Color(0xFF7C72FF),
          primaryTitle: t.borrowingDetails,
          primarySubtitle: t.borrowingDetailsSubtitle,
          paymentSubtitle: t.borrowedPaymentsSubtitle,
          scheduleSubtitle: t.borrowedScheduleSubtitle,
        );
    }
  }
}

class _LiabilitySpec {
  const _LiabilitySpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.primaryTitle,
    required this.primarySubtitle,
    required this.paymentSubtitle,
    required this.scheduleSubtitle,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String primaryTitle;
  final String primarySubtitle;
  final String paymentSubtitle;
  final String scheduleSubtitle;
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.account, required this.spec});

  final Account account;
  final _LiabilitySpec spec;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Container(
      padding: EdgeInsets.all(m.spacing(18)),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1C29),
        borderRadius: BorderRadius.circular(m.radius.xl),
        border: Border.all(color: spec.accent.withValues(alpha: .32)),
      ),
      child: Row(
        children: [
          Container(
            width: m.size(58),
            height: m.size(58),
            decoration: BoxDecoration(
              color: spec.accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(m.radius.lg),
            ),
            child: Icon(spec.icon, color: spec.accent, size: m.icon.large),
          ),
          SizedBox(width: m.space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: m.space.xs),
                Text(
                  '${spec.title} • ${account.currency}',
                  style: TextStyle(color: Colors.white54, fontSize: m.typography.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.spec, required this.outstanding});

  final _LiabilitySpec spec;
  final Money outstanding;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(m.spacing(18)),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1C29),
        borderRadius: BorderRadius.circular(m.radius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.outstanding, style: TextStyle(color: Colors.white54, fontSize: m.typography.caption)),
          SizedBox(height: m.space.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${outstanding.toDouble().toStringAsFixed(2)} ${t.currency}',
              style: TextStyle(color: spec.accent, fontSize: m.text(25), fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Container(
      padding: EdgeInsets.all(m.spacing(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1C29),
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: m.icon.medium),
          SizedBox(width: m.space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: m.typography.body)),
                SizedBox(height: m.space.xs),
                Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: m.typography.caption)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

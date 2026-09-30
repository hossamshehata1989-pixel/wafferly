import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_details_projection_service.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../models/account.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';

class CreditCardAccountDetailsScreen extends StatelessWidget {
  const CreditCardAccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final service = CreditCardDetailsProjectionService();
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return FutureBuilder<CreditCardDetailsProjection?>(
      future: service.project(accountId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final projection = snapshot.data;
        if (projection == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text(t.creditCardNotFound)),
          );
        }

        final account = projection.account;
        final card = projection.profile;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
            title: Text(
              t.creditCard,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: m.typography.title),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              m.spacing(16),
              m.spacing(6),
              m.spacing(16),
              m.spacing(28),
            ),
            children: [
              _CardIdentity(account: account, profile: card),
              SizedBox(height: m.space.md),
              _ExposureCard(projection: projection),
              SizedBox(height: m.space.md),
              _CardFacts(account: account, profile: card),
              SizedBox(height: m.space.md),
              _SectionCard(
                title: t.purchases,
                subtitle: t.purchasesSubtitle,
                icon: Icons.receipt_long_rounded,
              ),
              SizedBox(height: m.space.sm),
              _SectionCard(
                title: t.statements,
                subtitle: card.statementDay == null
                    ? t.statementNotConfigured
                    : '${t.statementClosesOn} ${card.statementDay}',
                icon: Icons.description_outlined,
              ),
              SizedBox(height: m.space.sm),
              _SectionCard(
                title: t.installments,
                subtitle: t.installmentsSubtitle,
                icon: Icons.calendar_month_rounded,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardIdentity extends StatelessWidget {
  const _CardIdentity({required this.account, required this.profile});

  final Account account;
  final CreditCardProfile profile;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(m.spacing(18)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF112B3D), Color(0xFF081A27)],
        ),
        borderRadius: BorderRadius.circular(m.radius.xl),
        border: Border.all(
          color: const Color(0xFFFF3D81).withValues(alpha: .35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: m.size(58),
            height: m.size(58),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3D81).withValues(alpha: .14),
              borderRadius: BorderRadius.circular(m.radius.lg),
            ),
            child: Icon(
              Icons.credit_card_rounded,
              color: const Color(0xFFFF3D81),
              size: m.icon.large,
            ),
          ),
          SizedBox(width: m.space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: m.space.xs),
                Text(
                  '${account.provider ?? t.creditCard} • ${profile.cardNetwork ?? t.networkNotSet}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white60, fontSize: m.typography.caption),
                ),
                SizedBox(height: m.space.xs),
                Text(
                  profile.cardKind == 'virtual' ? t.virtualCard : t.physicalCard,
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

class _ExposureCard extends StatelessWidget {
  const _ExposureCard({required this.projection});

  final CreditCardDetailsProjection projection;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(m.spacing(18)),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1C29),
        borderRadius: BorderRadius.circular(m.radius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.creditExposure,
            style: TextStyle(
              color: Colors.white,
              fontSize: m.typography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: m.space.md),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  title: t.outstanding,
                  value: _money(projection.outstanding.toDouble(), projection.account.currency),
                  color: const Color(0xFFFF3D81),
                ),
              ),
              SizedBox(width: m.space.sm),
              Expanded(
                child: _Metric(
                  title: t.available,
                  value: _money(projection.available.toDouble(), projection.account.currency),
                  color: const Color(0xFF22E6A8),
                ),
              ),
            ],
          ),
          SizedBox(height: m.space.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  t.creditLimit,
                  style: TextStyle(color: Colors.white54, fontSize: m.typography.caption),
                ),
              ),
              SizedBox(width: m.space.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    _money(projection.profile.creditLimit.toDouble(), projection.account.currency),
                    style: TextStyle(color: Colors.white, fontSize: m.typography.body, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: m.space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(m.radius.sm),
            child: LinearProgressIndicator(
              value: projection.utilization,
              minHeight: m.size(8),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3D81)),
            ),
          ),
          SizedBox(height: m.space.xs),
          Text(
            '${(projection.utilization * 100).round()}% ${t.used}',
            style: TextStyle(color: Colors.white54, fontSize: m.typography.caption),
          ),
        ],
      ),
    );
  }
}

class _CardFacts extends StatelessWidget {
  const _CardFacts({required this.account, required this.profile});

  final Account account;
  final CreditCardProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final last4 = account.accountNumber?.isNotEmpty == true
        ? account.accountNumber
        : t.notSet;
    final cardKind = profile.cardKind == 'virtual' ? t.virtualCard : t.physicalCard;
    final network = profile.cardNetwork ?? t.networkNotSet;
    final statement = profile.statementDay?.toString() ?? t.notSet;
    final due = profile.paymentDueDay?.toString() ?? t.notSet;

    return _SectionCard(
      title: t.cardDetails,
      icon: Icons.badge_outlined,
      subtitle: '${t.last4}: $last4 • $cardKind • $network\n'
          '${t.statementDay}: $statement • ${t.paymentDue}: $due',
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.icon});

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
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: m.typography.body),
                ),
                SizedBox(height: m.space.xs),
                Text(
                  subtitle,
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

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);

    return Container(
      padding: EdgeInsets.all(m.spacing(12)),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(m.radius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white54, fontSize: m.typography.caption)),
          SizedBox(height: m.space.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: m.text(15)),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double value, String currency) =>
    '${value.toStringAsFixed(2)} $currency';

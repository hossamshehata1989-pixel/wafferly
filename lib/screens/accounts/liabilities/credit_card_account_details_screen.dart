import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import '../../../models/account.dart';
import '../../../services/account_service.dart';
import '../../../services/balance_service.dart';

class CreditCardAccountDetailsScreen extends StatelessWidget {
  const CreditCardAccountDetailsScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final account = AccountService().getAccountById(accountId);
    if (account == null) {
      return const Scaffold(body: Center(child: Text('Credit card not found')));
    }

    final profile = HiveCreditCardProfileRepository(
      Hive.box<CreditCardProfile>('credit_card_profiles'),
    );

    return FutureBuilder<CreditCardProfile?>(
      future: profile.findByAccountId(accountId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final card = snapshot.data;
        if (card == null) {
          return const Scaffold(body: Center(child: Text('Credit card configuration not found')));
        }

        final balance = BalanceService().getBalance(accountId);
        final outstanding = math.max(0, -balance).toDouble();
        final limit = card.creditLimit.toDouble();
        final available = math.max(0, limit - outstanding).toDouble();
        final utilization = limit <= 0 ? 0.0 : (outstanding / limit).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFF020D16),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
            title: const Text('Credit Card', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            children: [
              _CardIdentity(account: account, profile: card),
              const SizedBox(height: 14),
              _ExposureCard(
                outstanding: outstanding,
                limit: limit,
                available: available,
                utilization: utilization,
                currency: account.currency,
              ),
              const SizedBox(height: 14),
              _CardFacts(account: account, profile: card),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Purchases',
                subtitle: 'Credit card transactions will appear here.',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: 10),
              _SectionCard(
                title: 'Statements',
                subtitle: card.statementDay == null ? 'Statement day is not configured.' : 'Statement closes on day ${card.statementDay}.',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 10),
              _SectionCard(
                title: 'Installments',
                subtitle: 'Financing conversions linked to this card will appear here.',
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF112B3D), Color(0xFF081A27)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF3D81).withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFFF3D81).withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.credit_card_rounded, color: Color(0xFFFF3D81), size: 30)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(account.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('${account.provider ?? 'Credit Card'} • ${profile.cardNetwork ?? 'Network not set'}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 3),
            Text(profile.cardKind == 'virtual' ? 'Virtual card' : 'Physical card', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
        ],
      ),
    );
  }
}

class _ExposureCard extends StatelessWidget {
  const _ExposureCard({required this.outstanding, required this.limit, required this.available, required this.utilization, required this.currency});
  final double outstanding;
  final double limit;
  final double available;
  final double utilization;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF0A1C29), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Credit Exposure', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _Metric(title: 'Outstanding', value: _money(outstanding, currency), color: const Color(0xFFFF3D81))),
          const SizedBox(width: 10),
          Expanded(child: _Metric(title: 'Available', value: _money(available, currency), color: const Color(0xFF22E6A8))),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Credit Limit', style: TextStyle(color: Colors.white54, fontSize: 11)),
          Text(_money(limit, currency), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: utilization, minHeight: 8, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3D81)))),
        const SizedBox(height: 7),
        Text('${(utilization * 100).round()}% used', style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}

class _CardFacts extends StatelessWidget {
  const _CardFacts({required this.account, required this.profile});
  final Account account;
  final CreditCardProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Card Details',
      icon: Icons.badge_outlined,
      subtitle: 'Last 4: ${account.accountNumber?.isNotEmpty == true ? account.accountNumber : 'Not set'} • ${profile.cardKind == 'virtual' ? 'Virtual' : 'Physical'} • ${profile.cardNetwork ?? 'Network not set'}\nStatement: ${profile.statementDay?.toString() ?? 'Not set'} • Payment due: ${profile.paymentDueDay?.toString() ?? 'Not set'}',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0A1C29), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .07))),
      child: Row(children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
      ]),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}

String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';

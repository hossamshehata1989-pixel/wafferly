import 'package:flutter/material.dart';

const Color liabilityPageBackground = Color(0xFF020D16);
const Color liabilitySurface = Color(0xFF0A1C29);

class LiabilityIdentityCard extends StatelessWidget {
  const LiabilityIdentityCard({
    super.key,
    required this.name,
    required this.typeLabel,
    required this.currency,
    required this.icon,
    required this.accent,
    this.secondaryLabel,
  });

  final String name;
  final String typeLabel;
  final String currency;
  final IconData icon;
  final Color accent;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: .18), liabilitySurface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .32)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  typeLabel,
                  style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (secondaryLabel != null && secondaryLabel!.isNotEmpty) secondaryLabel!,
                    currency,
                  ].join(' • '),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiabilityOutstandingCard extends StatelessWidget {
  const LiabilityOutstandingCard({
    super.key,
    required this.outstanding,
    required this.currency,
    required this.accent,
    this.secondaryMetricTitle,
    this.secondaryMetricValue,
  });

  final double outstanding;
  final String currency;
  final Color accent;
  final String? secondaryMetricTitle;
  final String? secondaryMetricValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: liabilitySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              title: 'Outstanding',
              value: _money(outstanding, currency),
              color: accent,
            ),
          ),
          if (secondaryMetricTitle != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                title: secondaryMetricTitle!,
                value: secondaryMetricValue ?? 'Not configured',
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LiabilitySectionCard extends StatelessWidget {
  const LiabilitySectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: liabilitySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );

    return onTap == null
        ? child
        : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: child);
  }
}

class LiabilityDetailScaffold extends StatelessWidget {
  const LiabilityDetailScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: liabilityPageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: actions,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: children,
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
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

String _money(double value, String currency) => '${value.toStringAsFixed(2)} $currency';

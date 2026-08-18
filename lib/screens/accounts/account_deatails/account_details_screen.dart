
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../models/account.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../core/planning/services/available_balance_projection_service.dart';
import '../../../services/financial_action_engine.dart';
import '../../../services/providers/commitment_action_provider.dart';
import '../../../services/schedule_evaluator.dart';

import 'account_details_logic.dart';
import 'account_details_models.dart';
import 'data/account_details_repository.dart';
import 'data/hive_account_details_repository.dart';


/// Stage 10 — Explicit responsive sizing; no global scale.
/// Page-local density override.
/// Keeps the existing responsive breakpoints/layout logic intact while
/// rendering this screen at 75% of its previous visual density.
class _AccountPageMetrics {
  // Stage 10: no global scaling.
  // Keep sizing explicit and responsive so important text/icons remain readable
  // on iPhone SE instead of shrinking the entire page uniformly.
  final ResponsiveMetrics base;

  _AccountPageMetrics(this.base);

  bool get isMobile => base.isMobile;
  bool get isTablet => base.isTablet;
  bool get isDesktop => base.isDesktop;
  bool get isCompactHeight => base.isCompactHeight;

  double size(double value) => base.size(value);
  double spacing(double value) => base.spacing(value);
  double h(double value) => base.h(value);
  double text(double value) => base.text(value);

  get typography => base.typography;
  get icon => base.icon;
}

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key, required this.accountId});

  final String accountId;

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late final AccountDetailsRepository _repository;
  late Future<AccountDetailsData> _future;
  int _tab = 0;
  _AccountChartPeriod _chartPeriod = _AccountChartPeriod.sixMonths;

  @override
  void initState() {
    super.initState();
    _repository = HiveAccountDetailsRepository(
      projectionService: context.read<AvailableBalanceProjectionService>(),
      actionEngine: FinancialActionEngine(
        providers: [
          CommitmentActionProvider(evaluator: const ScheduleEvaluator()),
        ],
      ),
    );
    _future = AccountDetailsLogic.load(
      repository: _repository,
      accountId: widget.accountId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _AccountPageMetrics(ResponsiveMetrics.of(context));

    return Scaffold(
      backgroundColor: const Color(0xFF020D16),
      body: SafeArea(
        child: FutureBuilder<AccountDetailsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(
                error: snapshot.error,
                onRetry: () => setState(() {
                  _future = AccountDetailsLogic.load(
                    repository: _repository,
                    accountId: widget.accountId,
                  );
                }),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return const Center(
                child: Text(
                  'Account not found',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            // STEP: Keep the account action bar pinned while the account details scroll.
            return Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(
                        m: m,
                        data: data,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ResponsiveTop(
                        m: m,
                        data: data,
                        chartPeriod: _chartPeriod,
                        onChartPeriodChanged: (value) {
                          setState(() => _chartPeriod = value);
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        m.spacing(m.isDesktop ? 24 : 16),
                        m.spacing(14),
                        m.spacing(m.isDesktop ? 24 : 16),
                        // Leave enough room so the final content is never hidden
                        // behind the pinned action bar.
                        m.spacing(m.isMobile ? 104 : 92),
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _OverviewSection(
                          m: m,
                          data: data,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _PinnedAccountActions(m: m),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(m.isDesktop ? 24 : 16),
        m.spacing(m.isCompactHeight ? 8 : 12),
        m.spacing(m.isDesktop ? 24 : 16),
        m.spacing(6),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white70,
          ),
          SizedBox(width: m.spacing(6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(m.isDesktop ? 25 : 20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: m.h(3)),
                Text(
                  '${data.account.group.name}  ›  ${data.account.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .55),
                    fontSize: m.typography.body,
                  ),
                ),
              ],
            ),
          ),
          _SmallAction(icon: Icons.notifications_none_rounded, m: m),
          SizedBox(width: m.spacing(6)),
          _SmallAction(icon: Icons.more_vert_rounded, m: m),
        ],
      ),
    );
  }
}

class _ResponsiveTop extends StatelessWidget {
  const _ResponsiveTop({
    required this.m,
    required this.data,
    required this.chartPeriod,
    required this.onChartPeriodChanged,
  });

  final _AccountPageMetrics m;
  final AccountDetailsData data;
  final _AccountChartPeriod chartPeriod;
  final ValueChanged<_AccountChartPeriod> onChartPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m.spacing(m.isDesktop ? 24 : 16)),
      child: _HeroCard(
        m: m,
        data: data,
        chartPeriod: chartPeriod,
        onChartPeriodChanged: onChartPeriodChanged,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.m,
    required this.data,
    required this.chartPeriod,
    required this.onChartPeriodChanged,
  });

  final _AccountPageMetrics m;
  final AccountDetailsData data;
  final _AccountChartPeriod chartPeriod;
  final ValueChanged<_AccountChartPeriod> onChartPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final availableRatio = data.balance == 0
        ? 0.0
        : (data.available / data.balance).clamp(0.0, 1.0).toDouble();
    final reservedRatio = data.balance == 0
        ? 0.0
        : (data.reserved / data.balance).clamp(0.0, 1.0).toDouble();

    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STEP: Account identity + compact management actions.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AccountAvatar(m: m, account: data.account),
              SizedBox(width: m.spacing(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: m.spacing(8),
                      runSpacing: m.spacing(4),
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: m.isDesktop ? 300 : 170,
                          ),
                          child: Text(
                            data.account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: m.text(m.isDesktop ? 24 : 21),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StatusChip(
                          label: data.account.isArchived ? 'Archived' : 'Active',
                          active: !data.account.isArchived,
                          m: m,
                        ),
                      ],
                    ),
                    SizedBox(height: m.h(4)),
                    Text(
                      '${_prettyType(data.account.type)} Account • ${data.account.currency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .58),
                        fontSize: m.typography.body,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.star_border_rounded, color: Colors.white54),
              SizedBox(width: m.spacing(8)),
              const Icon(Icons.edit_outlined, color: Colors.white54),
              SizedBox(width: m.spacing(8)),
              const Icon(Icons.more_horiz_rounded, color: Colors.white54),
            ],
          ),

          SizedBox(height: m.spacing(m.isMobile ? 13 : 16)),

          // STEP: Total balance + small health card.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .58),
                        fontSize: m.typography.body,
                      ),
                    ),
                    SizedBox(height: m.h(3)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _money(data.balance),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: m.text(m.isDesktop ? 34 : 28),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ),
                        SizedBox(width: m.spacing(6)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            data.account.currency,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: m.typography.body,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: m.spacing(10)),
              _MiniHealthCard(m: m, data: data),
            ],
          ),

          SizedBox(height: m.spacing(12)),

          // STEP: Available + Reserved directly under total balance.
          Row(
            children: [
              Expanded(
                child: _BalanceMetricCard(
                  m: m,
                  title: 'Available',
                  subtitle: 'Available to spend',
                  amount: data.available,
                  currency: data.account.currency,
                  color: const Color(0xFF39D98A),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              SizedBox(width: m.spacing(8)),
              Expanded(
                child: _BalanceMetricCard(
                  m: m,
                  title: 'Reserved',
                  subtitle: 'Your reserved money',
                  amount: data.reserved,
                  currency: data.account.currency,
                  color: const Color(0xFFFFAA2C),
                  icon: Icons.lock_outline_rounded,
                ),
              ),
            ],
          ),

          SizedBox(height: m.spacing(10)),

          // STEP: Chart + Expected amount always share the same row.
          // Chart = 2/3, Expected = 1/3 at every breakpoint.
          // The Expected card uses a compact mobile presentation.
          SizedBox(
            height: m.h(m.isDesktop ? 205 : (m.isCompactHeight ? 174 : 190)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _AccountBalanceChart(
                    m: m,
                    data: data,
                    period: chartPeriod,
                    availableRatio: availableRatio,
                    reservedRatio: reservedRatio,
                    onPeriodChanged: onChartPeriodChanged,
                  ),
                ),
                SizedBox(width: m.spacing(m.isMobile ? 6 : 10)),
                Expanded(
                  flex: 1,
                  child: _ExpectedAmountCard(m: m, data: data),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showChartPeriodPicker(
    BuildContext context, {
    required _AccountChartPeriod current,
    required ValueChanged<_AccountChartPeriod> onChanged,
  }) {
    final m = ResponsiveMetrics.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF071823),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: Text(
                  'Chart period',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final period in _AccountChartPeriod.values)
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: m.spacing(4)),
                  leading: Icon(
                    period.icon,
                    color: period == current
                        ? const Color(0xFF39D98A)
                        : Colors.white54,
                  ),
                  title: Text(
                    period.label,
                    style: TextStyle(
                      color: period == current
                          ? const Color(0xFF39D98A)
                          : Colors.white,
                      fontWeight: period == current
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: period == current
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF39D98A),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onChanged(period);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniHealthCard extends StatelessWidget {
  const _MiniHealthCard({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    final score = data.health.score.clamp(0, 100).toDouble();
    final status = data.health.label;

    return Container(
      width: m.isMobile ? 124 : 142,
      height: m.isMobile ? 72 : 80,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF071B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF39D98A).withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39D98A).withValues(alpha: .05),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(
              painter: _ProfessionalHealthPainter(value: score / 100),
              child: Center(
                child: Text(
                  '${score.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF39D98A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectedAmountCard extends StatelessWidget {
  const _ExpectedAmountCard({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  double _expectedAvailable() {
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    var recurringNet = 0.0;
    for (final item in data.recurring) {
      final due = item.nextOccurrence;
      if (due == null || due.isAfter(monthEnd)) continue;
      recurringNet += item.isIncome ? item.amount : -item.amount;
    }

    return data.available + recurringNet;
  }

  @override
  Widget build(BuildContext context) {
    final expected = _expectedAvailable();
    final delta = expected - data.available;
    final monthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    final compact = m.isMobile;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(m.spacing(compact ? 7 : 12)),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B25),
        borderRadius: BorderRadius.circular(m.size(14)),
        border: Border.all(
          color: const Color(0xFF9B6CFF).withValues(alpha: .18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  compact ? 'Expected' : 'Expected amount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(compact ? 14.5 : 16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!compact)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: m.spacing(7),
                    vertical: m.spacing(4),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B6CFF).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(m.size(20)),
                  ),
                  child: Text(
                    'Recurring-based',
                    style: TextStyle(
                      color: Color(0xFFB58BFF),
                      fontSize: m.text(9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: m.spacing(compact ? 6 : 8)),
          Text(
            compact
                ? 'By ${monthEnd.day} ${_monthShort(monthEnd.month)}'
                : 'Expected available by ${monthEnd.day} ${_monthShort(monthEnd.month)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: compact ? 10 : m.typography.caption,
            ),
          ),
          SizedBox(height: m.h(compact ? 4 : 5)),
          Text(
            compact
                ? '${_compactMoney(expected)} ${data.account.currency}'
                : '${_money(expected)} ${data.account.currency}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFB58BFF),
              fontSize: m.text(compact ? 19 : (m.isDesktop ? 26 : 23)),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: m.h(compact ? 3 : 4)),
          Text(
            '${delta >= 0 ? '↑' : '↓'} ${compact ? _compactMoney(delta.abs()) : _money(delta.abs())} ${data.account.currency}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: delta >= 0
                  ? const Color(0xFF39D98A)
                  : const Color(0xFFFF5B67),
              fontSize: compact ? 9 : m.typography.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (compact) ...[
            const Spacer(),
            InkWell(
              onTap: () => _showWhy(context),
              borderRadius: BorderRadius.circular(m.size(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Why?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: m.text(8.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: m.spacing(2)),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white54,
                    size: 12,
                  ),
                ],
              ),
            ),
          ] else ...[
            const Spacer(),
            InkWell(
              onTap: () => _showWhy(context),
              borderRadius: BorderRadius.circular(m.size(10)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: m.spacing(10),
                  vertical: m.spacing(8),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .025),
                  borderRadius: BorderRadius.circular(m.size(10)),
                  border: Border.all(color: Colors.white.withValues(alpha: .06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Why is this expected?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          fontSize: m.typography.caption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _compactMoney(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}K';
    }
    return value.toStringAsFixed(0);
  }

  static void _showWhy(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF071823),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why is this expected?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: m.text(18),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: m.spacing(12)),
              Text(
                'This first version uses the current available balance plus scheduled recurring income and expenses due before the end of the month. It does not yet use a prediction engine for new or variable expenses.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

enum _AccountChartPeriod {
  sevenDays,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  all;

  String get label => switch (this) {
        _AccountChartPeriod.sevenDays => '7 Days',
        _AccountChartPeriod.oneMonth => '1 Month',
        _AccountChartPeriod.threeMonths => '3 Months',
        _AccountChartPeriod.sixMonths => '6 Months',
        _AccountChartPeriod.oneYear => '1 Year',
        _AccountChartPeriod.all => 'All',
      };

  IconData get icon => switch (this) {
        _AccountChartPeriod.sevenDays => Icons.view_week_rounded,
        _AccountChartPeriod.oneMonth => Icons.calendar_month_rounded,
        _AccountChartPeriod.threeMonths => Icons.calendar_view_month_rounded,
        _AccountChartPeriod.sixMonths => Icons.date_range_rounded,
        _AccountChartPeriod.oneYear => Icons.date_range_rounded,
        _AccountChartPeriod.all => Icons.history_rounded,
      };
}

class _TopFilter extends StatelessWidget {
  const _TopFilter({
    required this.m,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final _AccountPageMetrics m;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(m.size(10)),
      child: Container(
        constraints: BoxConstraints(maxWidth: m.isMobile ? 105 : 140),
        padding: EdgeInsets.symmetric(
          horizontal: m.spacing(9),
          vertical: m.spacing(7),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF061923).withValues(alpha: .75),
          borderRadius: BorderRadius.circular(m.size(10)),
          border: Border.all(
            color: Colors.white.withValues(alpha: .10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: m.size(m.isMobile ? 15 : 17),
              color: Colors.white70,
            ),
            SizedBox(width: m.spacing(5)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: m.isMobile ? 10 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: m.spacing(3)),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBalanceChart extends StatelessWidget {
  const _AccountBalanceChart({
    required this.m,
    required this.data,
    required this.period,
    required this.availableRatio,
    required this.reservedRatio,
    required this.onPeriodChanged,
  });

  final _AccountPageMetrics m;
  final AccountDetailsData data;
  final _AccountChartPeriod period;
  final double availableRatio;
  final double reservedRatio;
  final ValueChanged<_AccountChartPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final points = _periodPoints(data.chart, period);
    final available = [
      for (final point in points) point.value * availableRatio,
    ];
    final reserved = [
      for (final point in points) point.value * reservedRatio,
    ];

    final hasMovement = points.length > 1 &&
        points.map((point) => point.value).reduce(math.max) -
                points.map((point) => point.value).reduce(math.min) >
            0.01;

    // The chart lives inside the page CustomScrollView. Give it a finite
    // height so the Expanded chart area below receives bounded constraints.
    // Using only minHeight here leaves the Column unbounded on mobile.
    return Container(
      padding: EdgeInsets.fromLTRB(
        m.spacing(10),
        m.spacing(8),
        m.spacing(8),
        m.spacing(7),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF061923).withValues(alpha: .55),
        borderRadius: BorderRadius.circular(m.size(14)),
        border: Border.all(
          color: Colors.white.withValues(alpha: .055),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (final periodItem in _AccountChartPeriod.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: m.isMobile ? 1 : 2,
                          ),
                          child: _ChartRangeChip(
                            m: m,
                            label: periodItem.shortLabel,
                            selected: periodItem == period,
                            onTap: () => onPeriodChanged(periodItem),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: m.spacing(5)),
          Expanded(
            child: hasMovement
                ? CustomPaint(
                    painter: _AccountBalanceChartPainter(
                      points: points,
                      available: available,
                      reserved: reserved,
                      currency: data.account.currency,
                    ),
                    child: const SizedBox.expand(),
                  )
                : Center(
                    child: Text(
                      'No balance movement yet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .45),
                        fontSize: m.typography.caption,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: m.spacing(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: const Color(0xFF39D98A),
                label: 'Available',
                m: m,
              ),
              SizedBox(width: m.spacing(14)),
              _LegendDot(
                color: const Color(0xFFFFAA2C),
                label: 'Reserved',
                m: m,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<BalancePoint> _periodPoints(
    List<BalancePoint> source,
    _AccountChartPeriod period,
  ) {
    if (source.isEmpty) return const [];
    final count = switch (period) {
      _AccountChartPeriod.sevenDays => 2,
      _AccountChartPeriod.oneMonth => 2,
      _AccountChartPeriod.threeMonths => 3,
      _AccountChartPeriod.sixMonths => 6,
      _AccountChartPeriod.oneYear => source.length,
      _AccountChartPeriod.all => source.length,
    };
    if (source.length <= count) return source;
    return source.sublist(source.length - count);
  }
}

extension on _AccountChartPeriod {
  String get shortLabel => switch (this) {
        _AccountChartPeriod.sevenDays => '7D',
        _AccountChartPeriod.oneMonth => '1M',
        _AccountChartPeriod.threeMonths => '3M',
        _AccountChartPeriod.sixMonths => '6M',
        _AccountChartPeriod.oneYear => '1Y',
        _AccountChartPeriod.all => 'All',
      };
}

class _ChartRangeChip extends StatelessWidget {
  const _ChartRangeChip({
    required this.m,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _AccountPageMetrics m;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(m.size(20)),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: m.spacing(5)),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF39D98A)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(m.size(20)),
        ),
        child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF04131B) : Colors.white70,
          fontSize: m.text(m.isMobile ? 9.5 : 11),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BalanceMetricCard extends StatelessWidget {
  const _BalanceMetricCard({
    required this.m,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  final _AccountPageMetrics m;
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(m.spacing(11)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .025),
        borderRadius: BorderRadius.circular(m.size(13)),
        border: Border.all(color: Colors.white.withValues(alpha: .075)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: m.text(m.isMobile ? 13 : 15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                icon,
                color: color,
                size: m.size(m.isMobile ? 17 : 19),
              ),
            ],
          ),
          SizedBox(height: m.h(3)),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: m.text(m.isMobile ? 8.5 : 10),
            ),
          ),
          SizedBox(height: m.h(5)),
          Text(
            '${_money(amount)} $currency',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: m.text(m.isMobile ? 17 : 21),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.m,
  });

  final Color color;
  final String label;
  final _AccountPageMetrics m;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: m.spacing(5)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .65),
            fontSize: m.text(m.isMobile ? 9.5 : 11),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AccountBalanceChartPainter extends CustomPainter {
  const _AccountBalanceChartPainter({
    required this.points,
    required this.available,
    required this.reserved,
    required this.currency,
  });

  final List<BalancePoint> points;
  final List<double> available;
  final List<double> reserved;
  final String currency;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 28.0;
    const right = 7.0;
    const top = 12.0;
    const bottom = 23.0;

    final chartRect = Rect.fromLTRB(
      left,
      top,
      math.max(left + 1, size.width - right),
      math.max(top + 1, size.height - bottom),
    );

    final allValues = <double>[
      ...available,
      ...reserved,
    ];
    var minValue = allValues.reduce(math.min);
    var maxValue = allValues.reduce(math.max);

    if ((maxValue - minValue).abs() < 1) {
      minValue = 0;
      maxValue = math.max(1, maxValue);
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = chartRect.top +
          chartRect.height * i / 3;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final availablePaint = Paint()
      ..color = const Color(0xFF39D98A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final reservedPaint = Paint()
      ..color = const Color(0xFFFFAA2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawSeries(
      canvas,
      chartRect,
      available,
      minValue,
      maxValue,
      availablePaint,
    );
    _drawSeries(
      canvas,
      chartRect,
      reserved,
      minValue,
      maxValue,
      reservedPaint,
    );

    final lastX = points.length == 1
        ? chartRect.left
        : chartRect.left +
            chartRect.width * (points.length - 1) /
                (points.length - 1);

    final lastAvailableY = _yForValue(
      chartRect,
      available.last,
      minValue,
      maxValue,
    );

    final lastReservedY = _yForValue(
      chartRect,
      reserved.last,
      minValue,
      maxValue,
    );

    final availableDot = Paint()
      ..color = const Color(0xFF39D98A)
      ..style = PaintingStyle.fill;
    final reservedDot = Paint()
      ..color = const Color(0xFFFFAA2C)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(lastX, lastAvailableY),
      4,
      availableDot,
    );
    canvas.drawCircle(
      Offset(lastX, lastReservedY),
      3.5,
      reservedDot,
    );

    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final labels = _labelsForPoints(points);
    for (int i = 0; i < labels.length; i++) {
      final x = points.length == 1
          ? chartRect.left
          : chartRect.left +
              chartRect.width * i / (points.length - 1);

      labelPaint.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 8.0,
          fontWeight: FontWeight.w500,
        ),
      );
      labelPaint.layout();

      final dx = (x - labelPaint.width / 2)
          .clamp(chartRect.left, chartRect.right - labelPaint.width)
          .toDouble();

      labelPaint.paint(
        canvas,
        Offset(dx, chartRect.bottom + 6),
      );
    }

    final scalePainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 3; i++) {
      final value =
          maxValue - (maxValue - minValue) * i / 2;
      scalePainter.text = TextSpan(
        text: _formatCompact(value),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 7.5,
        ),
      );
      scalePainter.layout();
      scalePainter.paint(
        canvas,
        Offset(
          0,
          chartRect.top +
              chartRect.height * i / 2 -
              scalePainter.height / 2,
        ),
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    Rect rect,
    List<double> values,
    double minValue,
    double maxValue,
    Paint paint,
  ) {
    if (values.isEmpty) return;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? rect.left
          : rect.left + rect.width * i / (values.length - 1);
      final y = _yForValue(
        rect,
        values[i],
        minValue,
        maxValue,
      );

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? rect.left
          : rect.left + rect.width * i / (values.length - 1);
      final y = _yForValue(
        rect,
        values[i],
        minValue,
        maxValue,
      );
      canvas.drawCircle(Offset(x, y), 3.2, dotPaint);
    }
  }

  double _yForValue(
    Rect rect,
    double value,
    double minValue,
    double maxValue,
  ) {
    final range = math.max(1, maxValue - minValue);
    final normalized = ((value - minValue) / range).clamp(0.0, 1.0);
    return rect.bottom - normalized * rect.height;
  }

  List<String> _labelsForPoints(List<BalancePoint> points) {
    if (points.isEmpty) return const [];
    return points.map((point) => _monthShort(point.date.month)).toList();
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  @override
  bool shouldRepaint(covariant _AccountBalanceChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.available != available ||
        oldDelegate.reserved != reserved;
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    final health = data.health;

    final gauge = SizedBox(
      width: m.size(m.isMobile ? 108 : 128),
      height: m.size(m.isMobile ? 108 : 128),
      child: CustomPaint(
        painter: _HealthPainter(value: health.score / 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: const Color(0xFF39D98A),
                size: m.isMobile ? m.icon.medium : m.icon.large,
              ),
              SizedBox(height: m.h(4)),
              Text(
                health.label,
                style: TextStyle(
                  color: const Color(0xFF39D98A),
                  fontSize: m.text(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final points = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in health.points)
          Padding(
            padding: EdgeInsets.only(bottom: m.spacing(7)),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF39D98A),
                  size: 18,
                ),
                SizedBox(width: m.spacing(8)),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: m.typography.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Health',
            style: TextStyle(
              color: Colors.white,
              fontSize: m.text(17),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: m.spacing(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: m.size(m.isMobile ? 108 : 128),
                child: gauge,
              ),
              SizedBox(width: m.spacing(m.isMobile ? 10 : 14)),
              Expanded(child: points),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.m,
    required this.selected,
    required this.onChanged,
  });

  final _AccountPageMetrics m;
  final int selected;
  final ValueChanged<int> onChanged;

  static const labels = [
    'Overview',
    'Activity',
    'Committed',
    'Recurring',
    'Planning',
    'Account',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        m.spacing(24),
        m.spacing(12),
        m.spacing(24),
        0,
      ),
      child: SizedBox(
        height: m.h(46),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, __) => SizedBox(width: m.spacing(20)),
          itemBuilder: (_, index) {
            final active = index == selected;
            return InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(m.size(10)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: m.spacing(2)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF39D98A)
                            : Colors.white.withValues(alpha: .58),
                        fontSize: m.typography.body,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: m.h(10)),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? m.size(56) : 0,
                      height: 2,
                      color: const Color(0xFF39D98A),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.m,
    required this.data,
    required this.tab,
  });

  final _AccountPageMetrics m;
  final AccountDetailsData data;
  final int tab;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 1:
        return _ActivitySection(m: m, data: data);
      case 2:
        return _CommittedSection(m: m, data: data);
      case 3:
        return _RecurringSection(m: m, data: data);
      case 4:
        return _PlanningSection(m: m, data: data);
      case 5:
        return _AccountInfoSection(m: m, data: data);
      default:
        return _OverviewSection(m: m, data: data);
    }
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    final reservedCard = _ReservedPreviewCard(m: m, data: data);
    final recurringCard = _RecurringPreviewCard(m: m, data: data);
    final activityCard = _RecentActivityPanel(
      m: m,
      data: data,
    );

    // STEP: Reserved Money + Recurring stay side-by-side at every breakpoint.
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: reservedCard),
            SizedBox(width: m.spacing(m.isMobile ? 8 : 12)),
            Expanded(child: recurringCard),
          ],
        ),
        SizedBox(height: m.spacing(10)),
        activityCard,
      ],
    );
  }
}

class _ReservedPreviewCard extends StatelessWidget {
  const _ReservedPreviewCard({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFFAA2C),
                size: 20,
              ),
              SizedBox(width: m.spacing(7)),
              Expanded(
                child: Text(
                  m.isMobile ? 'Reserved' : 'Reserved Money',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(m.isMobile ? 14 : 16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SeeMoreText(
                m: m,
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: m.spacing(8)),
          if (m.isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total reserved',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .52),
                    fontSize: m.text(9),
                  ),
                ),
                SizedBox(height: m.h(3)),
                Text(
                  '${_money(data.reserved)} ${data.account.currency}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFFFAA2C),
                    fontSize: m.text(16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total reserved',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .52),
                      fontSize: m.typography.caption,
                    ),
                  ),
                ),
                Text(
                  '${_money(data.reserved)} ${data.account.currency}',
                  style: TextStyle(
                    color: const Color(0xFFFFAA2C),
                    fontSize: m.text(18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          SizedBox(height: m.spacing(8)),
          if (data.reserved == 0)
            _EmptyLine(m: m, text: 'No reserved money for this account.')
          else
            Container(
              padding: EdgeInsets.all(m.spacing(9)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .025),
                borderRadius: BorderRadius.circular(m.size(10)),
                border: Border.all(color: Colors.white.withValues(alpha: .055)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: m.size(30),
                    height: m.size(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFAA2C).withValues(alpha: .10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFFFFAA2C),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: m.spacing(7)),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reserved allocations',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: m.text(m.isMobile ? 10.5 : 12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: m.spacing(4)),
                        Flexible(
                          child: Text(
                            '${_money(data.reserved)} ${data.account.currency}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: const Color(0xFFFFAA2C),
                              fontSize: m.text(m.isMobile ? 10.5 : 12),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecurringPreviewCard extends StatelessWidget {
  const _RecurringPreviewCard({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    final items = data.recurring.take(3).toList();

    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sync_rounded,
                color: Color(0xFF9B6CFF),
                size: 20,
              ),
              SizedBox(width: m.spacing(7)),
              Expanded(
                child: Text(
                  'Recurring',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.text(m.isMobile ? 14 : 16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SeeMoreText(m: m, onTap: () {}),
            ],
          ),
          SizedBox(height: m.spacing(8)),
          if (items.isEmpty)
            _EmptyLine(
              m: m,
              text: 'No recurring actions linked to this account.',
            )
          else
            for (final item in items)
              Padding(
                padding: EdgeInsets.symmetric(vertical: m.spacing(5)),
                child: _PreviewRow(
                  m: m,
                  icon: item.isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  iconColor: item.isIncome
                      ? const Color(0xFF39D98A)
                      : const Color(0xFFFF5B67),
                  title: item.title,
                  subtitle: item.nextOccurrence == null
                      ? item.subtitle
                      : '${item.subtitle} • ${_shortDate(item.nextOccurrence)}',
                  amount:
                      '${item.isIncome ? '+' : '-'}${_money(item.amount)} ${item.currency}',
                  amountColor: item.isIncome
                      ? const Color(0xFF39D98A)
                      : const Color(0xFFFF5B67),
                ),
              ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.m,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
  });

  final _AccountPageMetrics m;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: m.size(30),
          height: m.size(30),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        SizedBox(width: m.spacing(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: m.typography.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .45),
                  fontSize: m.typography.caption,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: m.spacing(6)),
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: amountColor,
            fontSize: m.typography.caption,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    final items = data.activity.take(3).toList();

    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PanelTitle(m: m, title: 'Recent Transactions'),
              ),
              _SeeMoreText(m: m, onTap: () {}),
            ],
          ),
          SizedBox(height: m.spacing(8)),
          if (items.isEmpty)
            _EmptyLine(m: m, text: 'No transactions for this account yet.')
          else
            for (final item in items)
              Padding(
                padding: EdgeInsets.symmetric(vertical: m.spacing(7)),
                child: _PreviewRow(
                  m: m,
                  icon: item.isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  iconColor: item.isIncome
                      ? const Color(0xFF39D98A)
                      : const Color(0xFFFF5B67),
                  title: item.title,
                  subtitle: '${item.category} • ${_shortDate(item.date)}',
                  amount:
                      '${item.isIncome ? '+' : '-'}${_money(item.amount)} ${data.account.currency}',
                  amountColor: item.isIncome
                      ? const Color(0xFF39D98A)
                      : const Color(0xFFFF5B67),
                ),
              ),
        ],
      ),
    );
  }
}

class _SeeMoreText extends StatelessWidget {
  const _SeeMoreText({required this.m, required this.onTap});

  final _AccountPageMetrics m;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(m.size(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: m.spacing(4), vertical: m.spacing(4)),
        child: Text(
          'See more',
          style: TextStyle(
            color: const Color(0xFF4CA7FF),
            fontSize: m.typography.caption,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PinnedAccountActions extends StatelessWidget {
  const _PinnedAccountActions({required this.m});

  final _AccountPageMetrics m;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.swap_horiz_rounded, 'Transfer'),
      (Icons.lock_outline_rounded, 'Reserve'),
      (Icons.add_circle_outline_rounded, 'Add Income'),
      (Icons.sync_rounded, 'Add Recurring'),
      (Icons.more_horiz_rounded, 'More'),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        m.spacing(m.isDesktop ? 24 : 12),
        0,
        m.spacing(m.isDesktop ? 24 : 12),
        m.spacing(8),
      ),
      padding: EdgeInsets.all(m.isMobile ? 5 : 9),
      decoration: BoxDecoration(
        color: const Color(0xFF061923).withValues(alpha: .98),
        borderRadius: BorderRadius.circular(m.size(16)),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: m.isMobile ? 3 : 8),
            Expanded(
              child: _ActionButton(
                icon: actions[i].$1,
                label: actions[i].$2,
                compact: true,
                fill: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThisMonthPanel extends StatelessWidget {
  const _ThisMonthPanel({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(m: m, title: 'This Month Overview'),
          SizedBox(height: m.spacing(14)),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  m: m,
                  label: 'Total In',
                  value: data.monthIn,
                  currency: data.account.currency,
                  color: const Color(0xFF39D98A),
                ),
              ),
              Expanded(
                child: _Metric(
                  m: m,
                  label: 'Total Out',
                  value: data.monthOut,
                  currency: data.account.currency,
                  color: const Color(0xFFFF5B67),
                ),
              ),
              Expanded(
                child: _Metric(
                  m: m,
                  label: 'Net Change',
                  value: data.monthIn - data.monthOut,
                  currency: data.account.currency,
                  color: const Color(0xFF39D98A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChartPanel extends StatelessWidget {
  const _BalanceChartPanel({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    final hasMovement = data.chart.length > 1 &&
        data.chart.map((point) => point.value).reduce(math.max) -
                data.chart.map((point) => point.value).reduce(math.min) >
            0.01;

    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PanelTitle(m: m, title: 'Balance Over Time'),
              ),
              if (!m.isMobile)
                _ChartPeriodChip(m: m, label: 'This Month'),
            ],
          ),
          SizedBox(height: m.spacing(10)),
          if (!hasMovement)
            _ChartEmptyState(m: m)
          else
            SizedBox(
              height: m.isMobile
                  ? (m.isCompactHeight ? 128 : 150)
                  : (m.isCompactHeight ? 160 : 190),
              child: CustomPaint(
                painter: _BalanceChartPainter(data.chart),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommittedSection extends StatelessWidget {
  const _CommittedSection({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(m: m, title: 'Committed Money'),
          SizedBox(height: m.spacing(10)),
          Text(
            '${_money(data.reserved)} ${data.account.currency}',
            style: TextStyle(
              color: Colors.white,
              fontSize: m.text(23),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: m.h(3)),
          Text(
            data.balance == 0
                ? 'No committed ratio'
                : '${((data.reserved / data.balance) * 100).clamp(0, 100).toStringAsFixed(0)}% of total balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: m.typography.caption,
            ),
          ),
          SizedBox(height: m.spacing(12)),
          if (data.reserved == 0)
            _EmptyLine(m: m, text: 'No reserved money for this account.')
          else
            _MetricBar(
              m: m,
              label: 'Reserved money',
              value: data.reserved,
              max: data.balance.abs().clamp(1, double.infinity),
              color: const Color(0xFFFFAA2C),
              currency: data.account.currency,
            ),
        ],
      ),
    );
  }
}

class _RecurringSection extends StatelessWidget {
  const _RecurringSection({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(m: m, title: 'Recurring'),
          SizedBox(height: m.spacing(12)),
          if (data.recurring.isEmpty)
            _EmptyLine(
              m: m,
              text: 'No recurring financial actions are currently linked to this account.',
            )
          else
            ...data.recurring.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: m.spacing(8)),
                child: _RecurringTile(m: m, item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({required this.m, required this.item});

  final _AccountPageMetrics m;
  final RecurringAccountItem item;

  @override
  Widget build(BuildContext context) {
    final income = item.isIncome;
    return Container(
      padding: EdgeInsets.all(m.spacing(12)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(m.size(12)),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          Icon(
            income ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: income
                ? const Color(0xFF39D98A)
                : const Color(0xFFFF5B67),
            size: m.icon.medium,
          ),
          SizedBox(width: m.spacing(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: m.typography.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: m.h(2)),
                Text(
                  '${item.subtitle} • Next ${_shortDate(item.nextOccurrence)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .5),
                    fontSize: m.typography.caption,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${income ? '+' : '-'}${_money(item.amount)} ${item.currency}',
            style: TextStyle(
              color: income
                  ? const Color(0xFF39D98A)
                  : const Color(0xFFFF5B67),
              fontSize: m.typography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningSection extends StatelessWidget {
  const _PlanningSection({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(m: m, title: 'Planning'),
          SizedBox(height: m.spacing(10)),
          Text(
            'Available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: m.typography.body,
            ),
          ),
          SizedBox(height: m.h(2)),
          Text(
            '${_money(data.available)} ${data.account.currency}',
            style: TextStyle(
              color: const Color(0xFF39D98A),
              fontSize: m.text(22),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: m.spacing(14)),
          _EmptyLine(
            m: m,
            text: 'Planning allocations are read from the Planning projection.',
          ),
        ],
      ),
    );
  }
}

class _AccountInfoSection extends StatelessWidget {
  const _AccountInfoSection({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Account Type', _prettyType(data.account.type)),
      MapEntry('Group', data.account.group.name),
      MapEntry('Currency', data.account.currency),
      if ((data.account.accountNumber ?? '').isNotEmpty)
        MapEntry('Account Number', data.account.accountNumber!),
      if ((data.account.provider ?? '').isNotEmpty)
        MapEntry('Provider', data.account.provider!),
      MapEntry('Created', _shortDate(data.account.createdAt)),
      if ((data.account.notes ?? '').isNotEmpty)
        MapEntry('Notes', data.account.notes!),
    ];

    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(m: m, title: 'Account Info'),
          SizedBox(height: m.spacing(8)),
          for (final row in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: m.spacing(7)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.key,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .55),
                        fontSize: m.typography.body,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .88),
                        fontSize: m.typography.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: _ActivityContent(m: m, data: data),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    required this.m,
    required this.data,
    this.compact = false,
  });

  final _AccountPageMetrics m;
  final AccountDetailsData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = compact ? data.activity.take(4).toList() : data.activity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelTitle(m: m, title: 'Recent Activity'),
        SizedBox(height: m.spacing(8)),
        if (items.isEmpty)
          _EmptyLine(m: m, text: 'No transactions for this account yet.')
        else
          for (final item in items)
            Padding(
              padding: EdgeInsets.symmetric(vertical: m.spacing(7)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: m.size(16),
                    backgroundColor: item.isIncome
                        ? const Color(0xFF39D98A).withValues(alpha: .12)
                        : const Color(0xFFFF5B67).withValues(alpha: .12),
                    child: Icon(
                      item.isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: item.isIncome
                          ? const Color(0xFF39D98A)
                          : const Color(0xFFFF5B67),
                      size: m.icon.small,
                    ),
                  ),
                  SizedBox(width: m.spacing(9)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: m.typography.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.category} • ${_shortDate(item.date)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .45),
                            fontSize: m.typography.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.isIncome ? '+' : '-'}${_money(item.amount)} ${data.account.currency}',
                    style: TextStyle(
                      color: item.isIncome
                          ? const Color(0xFF39D98A)
                          : const Color(0xFFFF5B67),
                      fontSize: m.typography.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _InsightsPanel extends StatelessWidget {
  const _InsightsPanel({required this.m, required this.data});

  final _AccountPageMetrics m;
  final AccountDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(m: m, title: 'Insights'),
          SizedBox(height: m.spacing(10)),
          _Insight(
            m: m,
            icon: Icons.trending_up_rounded,
            text: data.monthIn >= data.monthOut
                ? 'This account grew during the current month.'
                : 'This account decreased during the current month.',
          ),
          SizedBox(height: m.spacing(7)),
          _Insight(
            m: m,
            icon: Icons.account_balance_wallet_outlined,
            text: data.available > 0
                ? 'The account currently has available money.'
                : 'No available balance is currently projected.',
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.m});

  final _AccountPageMetrics m;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      m: m,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(m: m, title: 'Quick Actions'),
          SizedBox(height: m.spacing(10)),
          Wrap(
            spacing: m.spacing(8),
            runSpacing: m.spacing(8),
            children: const [
              _ActionButton(icon: Icons.edit_outlined, label: 'Edit'),
              _ActionButton(
                icon: Icons.settings_outlined,
                label: 'Account Settings',
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share Account',
              ),
              _ActionButton(
                icon: Icons.description_outlined,
                label: 'Export Statement',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.m});

  final _AccountPageMetrics m;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.swap_horiz_rounded, 'Transfer'),
      (Icons.lock_outline_rounded, 'Reserve'),
      (Icons.add_circle_outline_rounded, 'Add Income'),
      (Icons.description_outlined, 'Statement'),
      (Icons.more_horiz_rounded, 'More'),
    ];

    if (!m.isMobile) {
      return Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: m.spacing(8)),
            Expanded(
              child: _ActionButton(
                icon: actions[i].$1,
                label: actions[i].$2,
                compact: true,
                fill: true,
              ),
            ),
          ],
        ],
      );
    }

    final primary = actions.take(4).toList();
    final more = actions.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < primary.length; i++) ...[
              if (i > 0) SizedBox(width: m.spacing(6)),
              Expanded(
                child: _ActionButton(
                  icon: primary[i].$1,
                  label: primary[i].$2,
                  compact: true,
                  fill: true,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: m.spacing(8)),
        _ActionButton(
          icon: more.$1,
          label: more.$2,
          compact: true,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.compact = false,
    this.fill = false,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final m = _AccountPageMetrics(ResponsiveMetrics.of(context));

    return Container(
      width: fill
          ? null
          : compact
              ? m.size(m.isMobile ? 72 : 92)
              : m.size(m.isMobile ? 96 : 100),
      height: compact ? (m.isMobile ? 50 : 72) : null,
      padding: EdgeInsets.symmetric(
        horizontal: m.spacing(5),
        vertical: m.spacing(compact ? 5 : 11),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(m.size(10)),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: m.isMobile ? m.size(19) : m.icon.medium,
          ),
          SizedBox(height: m.h(4)),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: m.isMobile ? 8.5 : m.typography.caption,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSplit extends StatelessWidget {
  const _BalanceSplit({
    required this.m,
    required this.title,
    required this.amount,
    required this.currency,
    required this.ratio,
    required this.color,
  });

  final _AccountPageMetrics m;
  final String title;
  final double amount;
  final String currency;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(m.spacing(m.isMobile ? 10 : 11)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(m.size(10)),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: m.typography.caption,
            ),
          ),
          SizedBox(height: m.h(4)),
          Text(
            '${_money(amount)} $currency',
            style: TextStyle(
              color: color,
              fontSize: m.text(m.isMobile ? 16 : 17),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: m.h(7)),
          ClipRRect(
            borderRadius: BorderRadius.circular(m.size(20)),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: ratio,
              backgroundColor: Colors.white.withValues(alpha: .07),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.m,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.currency,
  });

  final _AccountPageMetrics m;
  final String label;
  final double value;
  final double max;
  final Color color;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: m.typography.body,
                ),
              ),
            ),
            Text(
              '${_money(value)} $currency',
              style: TextStyle(
                color: color,
                fontSize: m.typography.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: m.h(7)),
        LinearProgressIndicator(
          minHeight: 5,
          value: ratio,
          backgroundColor: Colors.white.withValues(alpha: .07),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.m,
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });

  final _AccountPageMetrics m;
  final String label;
  final double value;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: m.typography.caption,
          ),
        ),
        SizedBox(height: m.h(4)),
        Text(
          '${value >= 0 ? '+' : ''}${_money(value)}',
          style: TextStyle(
            color: color,
            fontSize: m.text(17),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          currency,
          style: TextStyle(
            color: color.withValues(alpha: .8),
            fontSize: m.typography.caption,
          ),
        ),
      ],
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({
    required this.m,
    required this.icon,
    required this.text,
  });

  final _AccountPageMetrics m;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(m.spacing(10)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(m.size(10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF39D98A), size: m.icon.medium),
          SizedBox(width: m.spacing(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                fontSize: m.typography.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.m, required this.child});

  final _AccountPageMetrics m;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.spacing(m.isMobile ? 13 : 16)),
      decoration: BoxDecoration(
        color: const Color(0xFF061521),
        borderRadius: BorderRadius.circular(m.size(m.isMobile ? 14 : 16)),
        border: Border.all(
          color: Colors.white.withValues(alpha: .07),
        ),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.m, required this.title});

  final _AccountPageMetrics m;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        color: Colors.white,
        fontSize: m.text(16),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.active,
    required this.m,
  });

  final String label;
  final bool active;
  final _AccountPageMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: m.spacing(8),
        vertical: m.spacing(4),
      ),
      decoration: BoxDecoration(
        color: (active ? const Color(0xFF39D98A) : Colors.white54)
            .withValues(alpha: .12),
        borderRadius: BorderRadius.circular(m.size(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF39D98A) : Colors.white60,
          fontSize: m.typography.caption,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.m, required this.account});

  final _AccountPageMetrics m;
  final Account account;

  @override
  Widget build(BuildContext context) {
    final asset = account.icon;

    return Container(
      width: m.size(64),
      height: m.size(64),
      padding: EdgeInsets.all(m.size(9)),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2638),
        borderRadius: BorderRadius.circular(m.size(14)),
        border: Border.all(
          color: const Color(0xFF35E0B5).withValues(alpha: .10),
        ),
      ),
      child: asset != null && asset.isNotEmpty
          ? SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                _iconForType(account.type),
                color: const Color(0xFF39D98A),
                size: m.icon.hero,
              ),
            )
          : Icon(
              _iconForType(account.type),
              color: const Color(0xFF39D98A),
              size: m.icon.hero,
            ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.m});

  final IconData icon;
  final _AccountPageMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: m.size(40),
      height: m.size(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(m.size(10)),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Icon(icon, color: Colors.white70, size: m.icon.medium),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.m, required this.text});

  final _AccountPageMetrics m;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.spacing(12)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .025),
        borderRadius: BorderRadius.circular(m.size(10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .5),
          fontSize: m.typography.body,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(m.spacing(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
            SizedBox(height: m.spacing(12)),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            SizedBox(height: m.spacing(12)),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPeriodChip extends StatelessWidget {
  const _ChartPeriodChip({required this.m, required this.label});

  final _AccountPageMetrics m;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: m.spacing(9),
        vertical: m.spacing(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(m.size(9)),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: m.icon.small, color: Colors.white60),
          SizedBox(width: m.spacing(5)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: m.typography.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: m.spacing(3)),
          Icon(Icons.keyboard_arrow_down_rounded, size: m.icon.small, color: Colors.white54),
        ],
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.m});

  final _AccountPageMetrics m;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: m.h(m.isMobile ? 112 : 130),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .018),
        borderRadius: BorderRadius.circular(m.size(12)),
        border: Border.all(color: Colors.white.withValues(alpha: .045)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, color: Colors.white24, size: m.icon.medium),
          SizedBox(height: m.spacing(5)),
          Text(
            'No balance movement yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .68),
              fontSize: m.typography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: m.h(2)),
          Text(
            'Your balance history will appear after transactions are recorded.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .38),
              fontSize: m.typography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalHealthPainter extends CustomPainter {
  const _ProfessionalHealthPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = const Color(0xFF39D98A).withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    final progress = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF20C982),
          Color(0xFF5BE39D),
          Color(0xFF20C982),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    const start = -math.pi * .75;
    const sweep = math.pi * 1.5;

    canvas.drawArc(rect, start, sweep, false, track);
    if (value > 0) {
      canvas.drawArc(rect, start, sweep * value.clamp(0, 1), false, glow);
      canvas.drawArc(rect, start, sweep * value.clamp(0, 1), false, progress);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfessionalHealthPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _HealthPainter extends CustomPainter {
  const _HealthPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final background = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final foreground = Paint()
      ..color = const Color(0xFF39D98A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * .75,
      math.pi * 1.5,
      false,
      background,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * .75,
      math.pi * 1.5 * value,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _BalanceChartPainter extends CustomPainter {
  const _BalanceChartPainter(this.points);

  final List<BalancePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final line = Paint()
      ..color = const Color(0xFF39D98A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dot = Paint()
      ..color = const Color(0xFF39D98A)
      ..style = PaintingStyle.fill;

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 1;

    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final min = points.map((e) => e.value).reduce(math.min);
    final max = points.map((e) => e.value).reduce(math.max);
    final range = (max - min).abs() < .01 ? 1 : (max - min);

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final normalized = (points[i].value - min) / range;
      final y = size.height - (normalized * (size.height - 18)) - 9;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3.5, dot);
    }

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

IconData _iconForType(String type) {
  final value = type.toLowerCase();
  if (value.contains('bank')) return Icons.account_balance_rounded;
  if (value.contains('wallet')) return Icons.account_balance_wallet_rounded;
  if (value.contains('card') || value.contains('credit')) {
    return Icons.credit_card_rounded;
  }
  if (value.contains('investment')) return Icons.trending_up_rounded;
  return Icons.payments_rounded;
}

String _prettyType(String type) {
  if (type.trim().isEmpty) return 'Account';
  return type
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

String _formatCompact(double value) {
  final absolute = value.abs();
  final sign = value < 0 ? '-' : '';

  if (absolute >= 1000000000) {
    return '$sign${(absolute / 1000000000).toStringAsFixed(1)}B';
  }
  if (absolute >= 1000000) {
    return '$sign${(absolute / 1000000).toStringAsFixed(1)}M';
  }
  if (absolute >= 1000) {
    return '$sign${(absolute / 1000).toStringAsFixed(1)}K';
  }

  if (absolute == absolute.roundToDouble()) {
    return '$sign${absolute.toStringAsFixed(0)}';
  }

  return '$sign${absolute.toStringAsFixed(1)}';
}

String _money(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '${value < 0 ? '-' : ''}$integer.${parts[1]}';
}

String _shortDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day}/${date.month}/${date.year}';
}
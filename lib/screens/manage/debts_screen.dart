import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/account.dart';
import '../../models/debt/debt_dashboard_summary.dart';
import '../../models/transaction.dart';
import 'credit_cards_screen.dart';

import '../../services/balance_service.dart';
import '../../services/debt_query_service.dart';

import '../../theme/debt_palette.dart';
import '../../theme/responsive_metrics.dart';

import '../accounts/account_details_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  late final DebtQueryService _queryService;

  Box<Account> get _accountBox =>
      Hive.box<Account>('accounts');

  Box<Commitment> get _commitmentBox =>
      Hive.box<Commitment>('commitments');

  Box<ScheduleRule> get _scheduleRuleBox =>
      Hive.box<ScheduleRule>('schedule_rules');

  Box<ScheduleOccurrence> get _occurrenceBox =>
      Hive.box<ScheduleOccurrence>('schedule_occurrences');

  Box<Transaction> get _transactionBox =>
      Hive.box<Transaction>('transactions');

  @override
  void initState() {
    super.initState();

    _queryService = DebtQueryService(
      balanceService: BalanceService(),
      accountBox: _accountBox,
      commitmentBox: _commitmentBox,
      scheduleRuleBox: _scheduleRuleBox,
      occurrenceBox: _occurrenceBox,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _accountBox.listenable(),
        _commitmentBox.listenable(),
        _scheduleRuleBox.listenable(),
        _occurrenceBox.listenable(),
        _transactionBox.listenable(),
      ]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            backgroundColor: scheme.surface,
            elevation: 0,
            toolbarHeight:
                ResponsiveMetrics.of(context).h(68),
            leading: BackButton(
              color: scheme.onSurface,
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Debts',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize:
                        ResponsiveMetrics.of(context).text(27),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(
                  height:
                      ResponsiveMetrics.of(context).h(6),
                ),
                Text(
                  'All your liabilities in one place.',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize:
                        ResponsiveMetrics.of(context).text(11.5),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _DashboardCanvas(
                  queryService: _queryService,
                  availableWidth: constraints.maxWidth,
                  availableHeight: constraints.maxHeight,
                  onOpenAccount: (account) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AccountDetailsScreen(
                          accountId: account.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DashboardCanvas extends StatelessWidget {
  final DebtQueryService queryService;
  final double availableWidth;
  final double availableHeight;
  final ValueChanged<Account> onOpenAccount;

  const _DashboardCanvas({
    required this.queryService,
    required this.availableWidth,
    required this.availableHeight,
    required this.onOpenAccount,
  });

  @override
  Widget build(BuildContext context) {
    final dashboard = queryService.getDebtDashboardSummary(
      today: DateTime.now(),
    );

    final categories = _categories(context, dashboard);
    final metrics = ResponsiveMetrics.of(context);
    final compact = availableWidth < 500 || availableHeight < 680;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? metrics.spacing(10) : metrics.spacing(12),
        metrics.h(4),
        compact ? metrics.spacing(10) : metrics.spacing(12),
        metrics.h(8),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 30,
            child: _SummaryCard(
              totalOutstanding: dashboard.totalOutstanding.toDouble(),
              thisMonth: dashboard.totalThisMonth.toDouble(),
              categories: categories,
              overdue: _stateTotals(dashboard.overdue),
              dueSoon: _stateTotals(dashboard.dueSoon),
              upcoming: _stateTotals(dashboard.upcoming),
              compact: compact,
            ),
          ),
          SizedBox(height: metrics.h(8)),
          Expanded(
            flex: 55,
            child: _CategoryGrid(
              categories: categories,
              onTap: onOpenAccount,
              compact: compact,
              cardHeight: math.max(
                0.0,
                (availableHeight - metrics.h(190) - metrics.h(60) - metrics.h(16)) / 3.0,
              ),
            ),
          ),
          SizedBox(height: metrics.h(8)),
          Expanded(
            flex: 15,
            child: const _ProgressCard(),
          ),
        ],
      ),
    );
  }

  List<_DebtCategory> _categories(
    BuildContext context,
    DebtDashboardSummary dashboard,
  ) {
    return [
      for (final item in dashboard.categories)
        _DebtCategory(
          title: item.title,
          icon: _iconForType(item.type),
          color: _colorForType(context, item.type),
          risk: _mapRisk(item.risk),
          accounts: item.accounts,
          outstanding: item.outstanding.toDouble(),
          thisMonth: item.thisMonth.toDouble(),
          countLabel: _countLabelForType(item.type),
          inactive: item.inactive,
        ),
    ];
  }

  _DebtRisk _mapRisk(DebtRisk risk) {
    return switch (risk) {
      DebtRisk.overdue => _DebtRisk.overdue,
      DebtRisk.critical => _DebtRisk.critical,
      DebtRisk.dueSoon => _DebtRisk.dueSoon,
      DebtRisk.upcoming => _DebtRisk.upcoming,
      DebtRisk.inactive => _DebtRisk.inactive,
    };
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'creditCard' => Icons.credit_card_rounded,
      'loan' => Icons.account_balance_rounded,
      'installment' => Icons.shopping_bag_rounded,
      'debt' => Icons.person_rounded,
      'temporaryDebt' => Icons.access_time_rounded,
      _ => Icons.groups_rounded,
    };
  }

  Color _colorForType(BuildContext context, String type) {
    final palette = context.debtPalette;
    return switch (type) {
      'creditCard' => palette.creditCards,
      'loan' => palette.loans,
      'installment' => palette.installments,
      'debt' => palette.borrowed,
      'temporaryDebt' => palette.temporary,
      _ => palette.rotating,
    };
  }

  String _countLabelForType(String type) {
    return switch (type) {
      'creditCard' => 'cards',
      'loan' => 'loans',
      'installment' => 'accounts',
      'debt' => 'people',
      'temporaryDebt' => 'items',
      _ => 'collections',
    };
  }

  _DebtStateTotals _stateTotals(DebtStateTotal total) {
    return _DebtStateTotals(
      count: total.count,
      amount: total.amount.toDouble(),
    );
  }
}

enum _DebtState { overdue, dueSoon, upcoming }

enum _DebtRisk { overdue, critical, dueSoon, upcoming, inactive }

class _DebtStateTotals {
  final int count;
  final double amount;

  const _DebtStateTotals({
    required this.count,
    required this.amount,
  });
}

class _DebtCategory {
  final String title;
  final IconData icon;
  final Color color;
  final _DebtRisk risk;
  final List<Account> accounts;
  final double outstanding;
  final double thisMonth;
  final String countLabel;
  final bool inactive;

  const _DebtCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.risk,
    required this.accounts,
    required this.outstanding,
    required this.thisMonth,
    required this.countLabel,
    required this.inactive,
  });
}

class _SummaryCard extends StatelessWidget {
  final double totalOutstanding;
  final double thisMonth;
  final List<_DebtCategory> categories;
  final _DebtStateTotals overdue;
  final _DebtStateTotals dueSoon;
  final _DebtStateTotals upcoming;
  final bool compact;

  const _SummaryCard({
    required this.totalOutstanding,
    required this.thisMonth,
    required this.categories,
    required this.overdue,
    required this.dueSoon,
    required this.upcoming,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final palette = context.debtPalette;
    final active = categories.where((item) => item.outstanding > 0).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(
        metrics.spacing(compact ? 10 : 12),
        metrics.h(compact ? 8 : 10),
        metrics.spacing(compact ? 10 : 12),
        metrics.h(7),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(metrics.size(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.summaryGradientStart,
            palette.summaryGradientEnd,
          ],
        ),
        border: Border.all(color: palette.summaryBorder),
        boxShadow: [
          BoxShadow(
            color: palette.summaryGlow.withOpacity(0.12),
            blurRadius: metrics.size(24),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // ===== الشمال: Total / This Month / 12% =====
      Expanded(
        flex: 4,
        child: _SummaryNumbers(
          totalOutstanding: totalOutstanding,
          thisMonth: thisMonth,
          compact: compact,
        ),
      ),

      // ===== اليمين: Donut + Legend =====
      Expanded(
        flex: 5,
        child: _DonutWithLegend(
                      categories: active,
                      total: totalOutstanding,
                    ),
      ),
    ],
  ),
),
          Container(height: metrics.h(1), color: palette.summaryDivider),
          SizedBox(height: metrics.h(7)),
          SizedBox(
            height: metrics.h(compact ? 44 : 49),
            child: Row(
              children: [
                Expanded(
                  child: _StateMetric(
                    state: 'Overdue',
                    value: overdue,
                    color: palette.overdue,
                  ),
                ),
                _divider(context, compact, palette),
                Expanded(
                  child: _StateMetric(
                    state: 'Due Soon',
                    value: dueSoon,
                    color: palette.dueSoon,
                  ),
                ),
                _divider(context, compact, palette),
                Expanded(
                  child: _StateMetric(
                    state: 'Upcoming',
                    value: upcoming,
                    color: palette.upcoming,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context, bool compact, DebtPalette palette) {
    final metrics = ResponsiveMetrics.of(context);
    return Container(
      width: metrics.size(1),
      height: metrics.h(compact ? 34 : 38),
      color: palette.summaryDivider,
    );
  }
}

class _SummaryNumbers extends StatelessWidget {
  final double totalOutstanding;
  final double thisMonth;
  final bool compact;

  const _SummaryNumbers({
    required this.totalOutstanding,
    required this.thisMonth,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = context.debtPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ===== Total Outstanding =====
        Text(
          'Total Outstanding',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: metrics.text(compact ? 10 : 11.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: metrics.h(2)),
        _Amount(
          value: totalOutstanding,
          size: metrics.text(compact ? 19 : 22),
          color: scheme.onSurface,
        ),
        SizedBox(height: metrics.h(5)),

        // ===== This Month =====
        Text(
          'This Month',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: metrics.text(compact ? 10 : 11.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: metrics.h(1)),
        _Amount(
          value: thisMonth,
          size: metrics.text(compact ? 15 : 17),
          color: palette.upcoming,
        ),
        SizedBox(height: metrics.h(5)),

        // ===== 12% vs last month =====
        Row(
          children: [
            Icon(
              Icons.north_east_rounded,
              color: palette.overdue,
              size: metrics.size(compact ? 14 : 16),
            ),
            SizedBox(width: metrics.spacing(2)),
            Text(
              '12%',
              style: TextStyle(
                color: palette.overdue,
                fontSize: metrics.text(compact ? 13 : 15),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: metrics.spacing(3)),
            Flexible(
              child: Text(
                'vs last month',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: metrics.text(compact ? 8 : 9.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class _DonutWithLegend extends StatelessWidget {
  final List<_DebtCategory> categories;
  final double total;

  const _DonutWithLegend({
    required this.categories,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ===== Donut =====
        SizedBox(
          width: metrics.size(90),
          height: metrics.h(90),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(metrics.size(90), metrics.size(90)),
                painter: _DonutPainter(
                  categories: categories,
                  total: total,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categories.length.toString(),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: metrics.text(18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'types',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: metrics.text(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(width: metrics.spacing(6)),

        // ===== Legend =====
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final category in categories.take(6))
                Padding(
                  padding: EdgeInsets.only(bottom: metrics.h(3)),
                  child: Row(
                    children: [
                      Container(
                        width: metrics.size(9),
                        height: metrics.size(9),
                        decoration: BoxDecoration(
                          color: category.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: metrics.spacing(4)),
                      Expanded(
                        child: Text(
                          _legendName(category.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: metrics.text(8.5),
                          ),
                        ),
                      ),
                      Text(
                        '${_percentage(category.outstanding, total)}%',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _legendName(String title) {
    switch (title) {
      case 'Installment Companies':
        return 'Installments';
      case 'Borrowed Money':
        return 'Borrowed';
      case 'Temporary Debt':
        return 'Temporary';
      case 'Rotating Savings (Collection)':
        return 'Rotating';
      default:
        return title;
    }
  }

  int _percentage(double value, double total) {
    if (total <= 0) return 0;
    return ((value / total) * 100).round();
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DebtCategory> categories;
  final double total;

  const _DonutPainter({
    required this.categories,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.butt;

    if (total <= 0) {
      paint.color = const Color(0xFF263A55);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    var start = -math.pi / 2;

    for (final category in categories) {
      if (category.outstanding <= 0) continue;

      final sweep = category.outstanding / total * math.pi * 2;

      paint.color = category.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.categories != categories;
  }
}

class _StateMetric extends StatelessWidget {
  final String state;
  final _DebtStateTotals value;
  final Color color;

  const _StateMetric({
    required this.state,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 500;

    return Row(
      children: [
        SizedBox(width: metrics.spacing(3)),
        Text(
          '${value.count}',
          style: TextStyle(
            color: color,
            fontSize: metrics.text(compact ? 18 : 21),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: metrics.spacing(5)),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: metrics.text(compact ? 8.5 : 10),
                ),
              ),
              SizedBox(height: metrics.h(1)),
              Text(
                _formatAmount(value.amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: metrics.text(compact ? 9 : 10.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<_DebtCategory> categories;
  final ValueChanged<Account> onTap;
  final bool compact;

  const _CategoryGrid({
    required this.categories,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final rowCount = (categories.length / 2).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = metrics.h(8) * (rowCount - 1);
        final rowHeight = (constraints.maxHeight - totalSpacing) / rowCount;

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: metrics.spacing(8),
            mainAxisSpacing: metrics.h(8),
            mainAxisExtent: rowHeight.clamp(0, double.infinity),
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _DebtCard(
              category: category,
              onTap: () {
                if (category.accounts.length == 1) {
                  onTap(category.accounts.first);
                } else if (category.accounts.length > 1) {
                  _showAccounts(context, category, onTap);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showAccounts(
    BuildContext context,
    _DebtCategory category,
    ValueChanged<Account> onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = ResponsiveMetrics.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(
              metrics.spacing(12),
              metrics.h(4),
              metrics.spacing(12),
              metrics.h(20),
            ),
            children: [
              Text(
                category.title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: metrics.text(20),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: metrics.h(8)),
              ...category.accounts.map(
                (account) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    category.icon,
                    color: category.color,
                  ),
                  title: Text(
                    account.name,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onTap(account);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DebtCard extends StatefulWidget {
  final _DebtCategory category;
  final VoidCallback onTap;

  const _DebtCard({
    required this.category,
    required this.onTap,
  });

  @override
  State<_DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<_DebtCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  _DebtCategory get category => widget.category;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _DebtCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.risk != widget.category.risk) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (category.risk == _DebtRisk.overdue) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ================================================================
  // Risk → intensity (0.0 → 1.0)
  // ================================================================
  double _riskIntensity(_DebtRisk risk) {
    switch (risk) {
      case _DebtRisk.upcoming:
        return 0.0;
      case _DebtRisk.dueSoon:
        return 0.35;
      case _DebtRisk.critical:
        return 0.65;
      case _DebtRisk.overdue:
        return 1.0;
      case _DebtRisk.inactive:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final palette = context.debtPalette;
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 500;

    final inactive = category.inactive;

    // ✅ identityColor = category color (Loans=blue, Cards=red, ...)
    final identityColor = inactive ? palette.inactive : category.color;

    // ✅ riskIntensity بتزود شدة الخلفية والـ glow
    final intensity = inactive ? 0.0 : _riskIntensity(category.risk);

    // ================================================================
    // Card gradient
    // Strong category color in the top-left → deep dark surface
    // ================================================================
    final Color cardStart = inactive
        ? Color.lerp(scheme.surface, palette.inactive, 0.08)!
        : Color.lerp(
            palette.cardSurface,
            identityColor,
            0.42 + intensity * 0.10,
          )!;

    final Color cardMiddle = inactive
        ? Color.lerp(scheme.surface, palette.inactive, 0.045)!
        : Color.lerp(
            palette.cardSurface,
            identityColor,
            0.20 + intensity * 0.07,
          )!;

    final Color cardEnd = inactive
        ? Color.lerp(scheme.surface, palette.inactive, 0.025)!
        : palette.cardSurface;

    final background = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cardStart,
        cardMiddle,
        cardEnd,
      ],
      stops: const [
        0.0,
        0.42,
        1.0,
      ],
    );

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = category.risk == _DebtRisk.overdue
            ? _pulseController.value
            : 0.0;

        final borderWidth = inactive ? 1.0 : 1.0 + pulse * 0.8;

        // ✅ البوردر بلون الـ category
        final borderColor = inactive
            ? palette.inactive.withOpacity(0.35)
            : identityColor.withOpacity(0.55 + pulse * 0.35);

        // ✅ الـ glow: بيزيد مع الـ risk
        final glowColor = category.risk == _DebtRisk.overdue
            ? palette.overdue
            : identityColor;

        final glowOpacity = inactive
            ? 0.0
            : (0.10 + intensity * 0.28) + pulse * 0.22;

        return Material(
          color: Colors.transparent,
          child: InkWell(
  borderRadius: BorderRadius.circular(metrics.size(15)),
  onTap: () {
    if (category.title == 'Credit Cards') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CreditCardsScreen(),
        ),
      );
      return;
    }

    widget.onTap();
  },
            child: Container(
              decoration: BoxDecoration(
                gradient: background,
                borderRadius: BorderRadius.circular(metrics.size(15)),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: inactive
                    ? null
                    : [
                        BoxShadow(
                          color: glowColor.withOpacity(glowOpacity),
                          blurRadius: metrics.size(14 + pulse * 16),
                          spreadRadius: pulse * metrics.size(1.5),
                        ),
                      ],
              ),
             padding: EdgeInsets.fromLTRB(
  metrics.spacing(compact ? 8 : 9),
  metrics.h(compact ? 3.5 : 6),
  metrics.spacing(compact ? 8 : 9),
  metrics.h(compact ? 3.5 : 6),
),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 180;
                  final iconSize = metrics.size(narrow ? 30 : 34);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============================================================
                      // Top row: Icon + Title + subtitle + Chevron
                      // ============================================================
                      Row(
                        children: [
                          _IconBubble(
                            icon: category.icon,
                            color: identityColor,
                            inactive: inactive,
                            surface: scheme.surface,
                            size: iconSize,
                            iconSize: metrics.size(narrow ? 17 : 19),
                          ),
                          SizedBox(width: metrics.spacing(7)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: inactive
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface,
                                    fontSize:
                                        metrics.text(narrow ? 11.5 : 12.5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: metrics.h(1)),
                                Text(
                                  inactive
                                      ? 'Inactive'
                                      : '${category.accounts.length} ${category.countLabel}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: inactive
                                        ? palette.inactive.withOpacity(0.7)
                                        : scheme.onSurfaceVariant
                                            .withOpacity(0.85),
                                    fontSize: metrics.text(narrow ? 8 : 8.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: inactive
                                ? palette.inactive
                                : scheme.onSurface.withOpacity(0.5),
                            size: metrics.size(narrow ? 18 : 20),
                          ),
                        ],
                      ),

                      SizedBox(height: metrics.h(6)),

                      // ============================================================
                      // Middle row: Total | This Month
                      // ============================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    color: inactive
                                        ? palette.inactive.withOpacity(0.7)
                                        : scheme.onSurfaceVariant,
                                    fontSize: metrics.text(narrow ? 8.5 : 9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: metrics.h(2)),
                                _Amount(
                                  value: category.outstanding,
                                  size: metrics.text(narrow ? 15 : 17),
                                  color: scheme.onSurface,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: metrics.h(30),
                            color: scheme.onSurface.withOpacity(0.18),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: metrics.spacing(6),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'This Month',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: inactive
                                          ? palette.inactive.withOpacity(0.7)
                                          : scheme.onSurfaceVariant,
                                      fontSize: metrics.text(narrow ? 8.5 : 9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: metrics.h(2)),
                                  Text(
                                    _formatAmount(category.thisMonth),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: inactive
                                          ? palette.inactive
                                          : identityColor,
                                      fontSize: metrics.text(narrow ? 13 : 15),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool inactive;
  final Color surface;
  final double size;
  final double iconSize;

  const _IconBubble({
    required this.icon,
    required this.color,
    required this.inactive,
    required this.surface,
    this.size = 34,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inactive
            ? Color.lerp(surface, color, 0.10)!
            : color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(metrics.size(10)),
      ),
      child: Icon(
        icon,
        color: inactive ? scheme.onSurfaceVariant : color,
        size: iconSize,
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final double value;
  final double size;
  final Color color;

  const _Amount({
    required this.value,
    required this.size,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: RichText(
        maxLines: 1,
        text: TextSpan(
          children: [
            TextSpan(
              text: _formatNumber(value),
              style: TextStyle(
                color: color,
                fontSize: size,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            TextSpan(
              text: ' EGP',
              style: TextStyle(
                color: color,
                fontSize: size * 0.50,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final palette = context.debtPalette;
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 500;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: metrics.spacing(11)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(metrics.size(16)),
        gradient: LinearGradient(
          colors: [
            palette.progressGradientStart,
            palette.progressGradientEnd,
          ],
        ),
        border: Border.all(color: palette.progressBorder),
      ),
      child: Row(
        children: [
          Container(
            width: metrics.size(compact ? 30 : 32),
            height: metrics.size(compact ? 30 : 32),
            decoration: BoxDecoration(
              color: palette.progressAccent.withOpacity(0.30),
              borderRadius: BorderRadius.circular(metrics.size(9)),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: palette.progressAccent,
              size: metrics.size(18),
            ),
          ),
          SizedBox(width: metrics.spacing(9)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're doing well!",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.progressAccent,
                    fontSize: metrics.text(compact ? 11 : 12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: metrics.h(2)),
                Text(
                  'Your total debt decreased by 12% this month.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: metrics.text(compact ? 8 : 9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurface,
            size: metrics.size(22),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(double value) {
  final rounded = value.round();
  final digits = rounded.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return buffer.toString();
}

String _formatAmount(double value) {
  return '${_formatNumber(value)} EGP';
}
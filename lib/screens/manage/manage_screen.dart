import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../models/enums/account_enums.dart';

import '../../models/enums/goal_status.dart';

import '../../models/scheduled_action_execution_context.dart';

import '../../models/enums/scheduled_action_kind.dart';

import '../../services/account_service.dart';

import '../../services/goal_service.dart';

import '../../services/budget_service.dart';

import '../../theme/responsive_metrics.dart';

import '../../services/balance_service.dart';

import '../../services/financial_action_engine.dart';

import '../../services/providers/commitment_action_provider.dart';

import '../../services/schedule_evaluator.dart';

import '../../services/reserved_money_projection_service.dart';

import '../../core/planning/services/available_balance_projection_service.dart';

import '../planning/planning_screen.dart';

import '../planning/reserved_money_screen.dart';

import 'outgoing_screen.dart';

import 'package:wafferly/features/financial_action_center/financial_action_center.dart';

/// Manage — redesigned around the user's financial system.
///
/// The screen is intentionally a read/launch surface:
/// - Financial Overview
/// - Financial Action Center preview
/// - Debts
/// - Recurring
/// - Goals
/// - Budgets
/// - Reserved Money
///
/// Existing engines/services remain the source of truth.
class ManageScreen extends StatefulWidget {

  const ManageScreen({super.key});

  @override

  State<ManageScreen> createState() => _ManageScreenState();

}

class _ManageScreenState extends State<ManageScreen> {

  late Future<_ManageData> _future;

  @override

  void initState() {

    super.initState();

    _future = _load();

  }

  Future<_ManageData> _load() {

    // Resolve all dependencies before entering async work. The loader itself
    // is a plain Dart class and never touches BuildContext.
    final availableProjectionService =

        context.read<AvailableBalanceProjectionService>();

    final reservedProjectionService =

        context.read<ReservedMoneyProjectionService>();

    return _ManageDataLoader(

      availableProjectionService: availableProjectionService,

      reservedProjectionService: reservedProjectionService,

      accountService: AccountService(),

      balanceService: BalanceService(),

      goalService: GoalService(),

      budgetService: BudgetService(),

    ).load();

  }

  Future<void> _refresh() async {

    final next = _load();

    if (!mounted) return;

    setState(() {

      _future = next;

    });

    await next;

  }

  void _openFinancialActions() {

    Navigator.of(context).push(

      MaterialPageRoute<void>(

        builder: (_) => Scaffold(

          backgroundColor: const Color(0xFF020914),

          appBar: AppBar(

            backgroundColor: const Color(0xFF020914),

            elevation: 0,

            title: const Text(

              'Financial Actions',

              style: TextStyle(

                color: Colors.white,

                fontWeight: FontWeight.w800,

              ),

            ),

          ),

          body: SafeArea(

            child: Padding(

              padding: EdgeInsets.all(ResponsiveMetrics.of(context).spacing(12)),

              child: FinancialActionCenter(

                onSkip: () => Navigator.of(context).pop(),

              ),

            ),

          ),

        ),

      ),

    ).then((_) => _refresh());

  }

  void _openGoals() {

    Navigator.of(context).push(

      MaterialPageRoute(builder: (_) => const PlanningScreen()),

    );

  }

  void _openBudgets() {

    Navigator.of(context).push(

      MaterialPageRoute(builder: (_) => const PlanningScreen()),

    );

  }

  void _openReservedMoney() {

    Navigator.of(context).push(

      MaterialPageRoute(builder: (_) => const ReservedMoneyScreen()),

    ).then((_) => _refresh());

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF020914),

      body: SafeArea(

        child: RefreshIndicator(

          onRefresh: _refresh,

          color: const Color(0xFFB995FF),

          backgroundColor: const Color(0xFF0B1422),

          child: FutureBuilder<_ManageData>(

            future: _future,

            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {

                return const Center(

                  child: CircularProgressIndicator(

                    color: Color(0xFFB995FF),

                  ),

                );

              }

              if (snapshot.hasError) {

                return _ErrorState(

                  message: snapshot.error.toString(),

                  onRetry: _refresh,

                );

              }

              final data = snapshot.data;

              if (data == null) {

                return _ErrorState(

                  message: 'Unable to load Manage.',

                  onRetry: _refresh,

                );

              }

              return CustomScrollView(

                physics: const AlwaysScrollableScrollPhysics(

                  parent: BouncingScrollPhysics(),

                ),

                slivers: [

                  SliverPadding(

                    padding: EdgeInsets.fromLTRB(ResponsiveMetrics.of(context).spacing(14), ResponsiveMetrics.of(context).h(7), ResponsiveMetrics.of(context).spacing(14), ResponsiveMetrics.of(context).h(22)),

                    sliver: SliverList(

                      delegate: SliverChildListDelegate([

                        _Header(onNotifications: () {}),

                        SizedBox(height: ResponsiveMetrics.of(context).h(10)),

                        _FinancialOverviewCard(

                          data: data,

                          onDetails: _openFinancialActions,

                        ),

                        SizedBox(height: ResponsiveMetrics.of(context).h(10)),

                        Builder(

                          builder: (context) {

                            final debts = _SystemCard(

  color: const Color(0xFFFF405A),

  icon: Icons.credit_card_rounded,

  title: 'Debts',

  subtitle: 'Loans, credit cards and borrowed money.',

  onTap: () {

    Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => const OutgoingScreen(),

      ),

    );

  },

  mustCount: data.debtCount,

  needCount: 0,

  wantCount: 0,

  footerCount: data.debtCount,

  footerLabel: 'active',

  footerAmount: data.totalCommitments,

  footerAmountLabel: 'due this month',

);

                            final recurring = _SystemCard(

  color: const Color(0xFF2585FF),

  icon: Icons.sync_rounded,

  title: 'Recurring',

  subtitle: 'Bills, subscriptions and recurring income.',

  onTap: () {

    Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => const OutgoingScreen(),

      ),

    );

  },

  mustCount: data.recurringCount,

  needCount: 0,

  wantCount: 0,

  footerCount: data.recurringCount,

  footerLabel: 'scheduled',

  footerAmount: data.totalCommitments,

  footerAmountLabel: 'this month',

);

                            return Row(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Expanded(child: debts),

                                SizedBox(width: ResponsiveMetrics.of(context).spacing(8)),

                                Expanded(child: recurring),

                              ],

                            );

                          },

                        ),

                        SizedBox(height: ResponsiveMetrics.of(context).h(8)),

                        _WideSystemCard(

                          color: const Color(0xFF19D89B),

                          icon: Icons.track_changes_rounded,

                          title: 'Goals',

                          subtitle: 'Track your goals and achieve what matters.',

                          metric: '${data.goalCount}',

                          metricLabel: 'active',

                          secondary: 'Planning',

                          onTap: _openGoals,

                        ),

                        SizedBox(height: ResponsiveMetrics.of(context).h(12)),

                        _WideSystemCard(

                          color: const Color(0xFF9C4DFF),

                          icon: Icons.pie_chart_rounded,

                          title: 'Budgets',

                          subtitle: 'Set limits and control your spending.',

                          metric: '${data.budgetCount}',

                          metricLabel: 'active',

                          secondary: 'Spending plans',

                          onTap: _openBudgets,

                        ),

                        SizedBox(height: ResponsiveMetrics.of(context).h(12)),

                        _WideSystemCard(

                          color: const Color(0xFFFFAA1F),

                          icon: Icons.lock_rounded,

                          title: 'Reserved Money',

                          subtitle: 'Money set aside for planned needs.',

                          metric: _formatMoneyMinor(data.reservedAmount),

                          metricLabel: 'EGP',

                          secondary:

                              '${data.reservationCount} reservations',

                          onTap: _openReservedMoney,

                        ),

                      ]),

                    ),

                  ),

                ],

              );

            },

          ),

        ),

      ),

    );

  }

}

int _toMinor(double amount) => (amount * 100).round();

String _formatMoneyMinor(int minorUnits) {

  final major = minorUnits ~/ 100;

  final sign = major < 0 ? '-' : '';

  final digits = major.abs().toString();

  final grouped = digits.replaceAllMapped(

    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),

    (match) => '${match[1]},',

  );

  return '$sign$grouped';

}

class _ManageDataLoader {

  _ManageDataLoader({

    required this.availableProjectionService,

    required this.reservedProjectionService,

    required this.accountService,

    required this.balanceService,

    required this.goalService,

    required this.budgetService,

  });

  final AvailableBalanceProjectionService availableProjectionService;

  final ReservedMoneyProjectionService reservedProjectionService;

  final AccountService accountService;

  final BalanceService balanceService;

  final GoalService goalService;

  final BudgetService budgetService;

  Future<_ManageData> load() async {

    final accounts = accountService.getAllActiveAccounts();

    final liquidity = accounts

        .where((a) => a.group == AccountGroup.liquidity)

        .toList();

    int totalBalanceMinor = 0;

    int totalAvailableAfterReservationsMinor = 0;

    for (final account in liquidity) {

      final balance = balanceService.getBalance(account.id);

      final projection = await availableProjectionService.project(

        accountId: account.id,

        balance: balance,

      );

      totalBalanceMinor += _toMinor(balance);

      totalAvailableAfterReservationsMinor += _toMinor(projection.available);

    }

    final actionEngine = FinancialActionEngine(

      providers: [

        CommitmentActionProvider(evaluator: const ScheduleEvaluator()),

      ],

    );

    final actions = await actionEngine.getActions(today: DateTime.now());

    final now = DateTime.now();

    final monthActions = actions.where((ctx) {

      final date = ctx.action.dueDate;

      return date.year == now.year && date.month == now.month;

    }).toList();

    final commitmentActions = monthActions.where((ctx) {

      final kind = ctx.action.kind.name;

      return kind == 'expense' || kind == 'liabilityPayment';

    }).toList();

    final commitmentTotalMinor = commitmentActions.fold<int>(

      0,

      (sum, item) => sum + _toMinor(item.action.amount),

    );

    final upcoming = List.of(actions)

      ..sort((a, b) => a.action.dueDate.compareTo(b.action.dueDate));

    final reservedProjection =

        await reservedProjectionService.getProjection();

    // Goals and Budgets are read through their application services.
    // Manage never opens Hive boxes directly, so the UI does not care whether
    // persistence is Hive today or Supabase later.
    final activeGoalCount = goalService

        .getAll()

        .where((goal) => goal.status == GoalStatus.active)

        .length;

    final budgetCount = budgetService.getAllBudgets().length;

    final debtCount = accounts

        .where((a) => a.group == AccountGroup.liabilities)

        .length;

    // CommitmentActionProvider currently represents the active scheduled
    // commitment set, so this is the scheduled/recurring item count.
    final recurringCount = actions.length;

    final availableToSpendMinor =

        (totalAvailableAfterReservationsMinor - commitmentTotalMinor).clamp(0, 1 << 62);

    return _ManageData(

      totalBalance: totalBalanceMinor,

      totalCommitments: commitmentTotalMinor,

      availableToSpend: availableToSpendMinor,

      commitmentCount: commitmentActions.length,

      upcoming: upcoming.take(6).toList(),

      debtCount: debtCount,

      recurringCount: recurringCount,

      goalCount: activeGoalCount,

      budgetCount: budgetCount,

      reservedAmount: _toMinor(reservedProjection.totalReserved),

      reservationCount: reservedProjection.items.length,

    );

  }

}

class _ManageData {

  final int totalBalance;

  final int totalCommitments;

  final int availableToSpend;

  final int commitmentCount;

  final List<ScheduledActionExecutionContext> upcoming;

  final int debtCount;

  final int recurringCount;

  final int goalCount;

  final int budgetCount;

  final int reservedAmount;

  final int reservationCount;

  const _ManageData({

    required this.totalBalance,

    required this.totalCommitments,

    required this.availableToSpend,

    required this.commitmentCount,

    required this.upcoming,

    required this.debtCount,

    required this.recurringCount,

    required this.goalCount,

    required this.budgetCount,

    required this.reservedAmount,

    required this.reservationCount,

  });

}

class _Header extends StatelessWidget {

  final VoidCallback onNotifications;

  const _Header({required this.onNotifications});

  @override

  Widget build(BuildContext context) {

    final compact = MediaQuery.sizeOf(context).width < 500;

    final metrics = ResponsiveMetrics.of(context);

    final titleSize = metrics.text(compact ? 27 : 36);

    final subtitleSize = metrics.text(compact ? 12 : 16);

    final bellSize = metrics.size(compact ? 21 : 25);

    final bellPadding = metrics.spacing(compact ? 10 : 14);

    return Row(

      crossAxisAlignment: CrossAxisAlignment.center,

      children: [

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                'Manage',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: titleSize,

                  fontWeight: FontWeight.w800,

                  letterSpacing: compact ? -.5 : -1,

                ),

              ),

              SizedBox(height: ResponsiveMetrics.of(context).h(1)),

              Text(

                'Organize. Plan. Achieve.',

                style: TextStyle(

                  color: const Color(0xFFA9B3C7),

                  fontSize: subtitleSize,

                  fontWeight: FontWeight.w500,

                ),

              ),

            ],

          ),

        ),

        Material(

          color: const Color(0xFF0B1422),

          shape: const CircleBorder(

            side: BorderSide(color: Colors.white12),

          ),

          child: InkWell(

            customBorder: const CircleBorder(),

            onTap: onNotifications,

            child: Padding(

              padding: EdgeInsets.all(bellPadding),

              child: Icon(

                Icons.notifications_none_rounded,

                color: Colors.white,

                size: bellSize,

              ),

            ),

          ),

        ),

      ],

    );

  }

}

class _FinancialOverviewCard extends StatelessWidget {

  final _ManageData data;

  final VoidCallback onDetails;

  const _FinancialOverviewCard({

    required this.data,

    required this.onDetails,

  });

  @override

  Widget build(BuildContext context) {

    return _Panel(

      borderColor: const Color(0xFF203553),

      child: Column(

        children: [

          LayoutBuilder(

            builder: (context, constraints) {

              final compact = constraints.maxWidth < 520;

              final metrics = ResponsiveMetrics.of(context);

              return Row(

                children: [

                  _IconBox(

                    color: const Color(0xFF9C4DFF),

                    icon: Icons.account_balance_wallet_rounded,

                    size: metrics.size(compact ? 44 : 56),

                  ),

                  SizedBox(width: metrics.spacing(compact ? 9 : 14)),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          'Financial Overview',

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(

                            color: Colors.white,

                            fontSize: metrics.text(compact ? 16 : 21),

                            fontWeight: FontWeight.w800,

                          ),

                        ),

                        SizedBox(height: ResponsiveMetrics.of(context).h(2)),

                        Text(

                          'Your commitments and available money',

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(

                            color: const Color(0xFFA9B3C7),

                            fontSize: metrics.text(compact ? 9 : 13),

                          ),

                        ),

                      ],

                    ),

                  ),

                  if (compact)

                    TextButton(

                      onPressed: onDetails,

                      style: TextButton.styleFrom(

                        minimumSize: Size.zero,

                        padding: EdgeInsets.symmetric(horizontal: ResponsiveMetrics.of(context).spacing(4)),

                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                      ),

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Text('Details', style: TextStyle(fontSize: ResponsiveMetrics.of(context).text(9))),

                          Icon(Icons.chevron_right_rounded, size: ResponsiveMetrics.of(context).size(16)),

                        ],

                      ),

                    )

                  else

                    TextButton(

                      onPressed: onDetails,

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Text('See Details'),

                          SizedBox(width: 3),

                          Icon(Icons.chevron_right_rounded, size: ResponsiveMetrics.of(context).size(20)),

                        ],

                      ),

                    ),

                ],

              );

            },

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(10)),

          Divider(color: Colors.white.withValues(alpha: .07), height: ResponsiveMetrics.of(context).h(1)),

          SizedBox(height: ResponsiveMetrics.of(context).h(8)),

          LayoutBuilder(

            builder: (context, constraints) {

              final compact = constraints.maxWidth < 520;

              final overviewMetrics = [

                _OverviewMetric(

                  icon: Icons.storage_rounded,

                  color: const Color(0xFF8392AD),

                  title: 'Total Commitments',

                  value: _money(data.totalCommitments),

                  unit: 'EGP',

                  subtitle: '${data.commitmentCount} items',

                  compact: compact,

                ),

                _OverviewMetric(

                  icon: Icons.account_balance_wallet_rounded,

                  color: const Color(0xFF9AA7BB),

                  title: 'Total Balance',

                  value: _money(data.totalBalance),

                  unit: 'EGP',

                  subtitle: 'Liquidity accounts',

                  compact: compact,

                ),

                _OverviewMetric(

                  icon: Icons.wallet_rounded,

                  color: const Color(0xFF19D89B),

                  title: 'Available to Spend',

                  value: _money(data.availableToSpend),

                  unit: 'EGP',

                  subtitle: 'After commitments',

                  compact: compact,

                ),

              ];

              return Row(

                crossAxisAlignment: CrossAxisAlignment.center,

                children: [

                  Expanded(child: overviewMetrics[0]),

                  _VerticalDivider(compact: compact),

                  Expanded(child: overviewMetrics[1]),

                  _VerticalDivider(compact: compact),

                  Expanded(child: overviewMetrics[2]),

                ],

              );

            },

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(9)),

          Divider(color: Colors.white.withValues(alpha: .07), height: ResponsiveMetrics.of(context).h(1)),

          SizedBox(height: ResponsiveMetrics.of(context).h(8)),

          LayoutBuilder(

            builder: (context, constraints) {

              final compact = constraints.maxWidth < 520;

              final metrics = ResponsiveMetrics.of(context);

              return Row(

                children: [

                  Icon(

                    Icons.notifications_active_outlined,

                    color: const Color(0xFFFF5265),

                    size: metrics.size(compact ? 16 : 21),

                  ),

                  SizedBox(width: metrics.spacing(compact ? 5 : 8)),

                  Expanded(

                    child: Text(

                      'Upcoming Due',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: compact ? 11 : 14,

                        fontWeight: FontWeight.w800,

                      ),

                    ),

                  ),

                  TextButton(

                    onPressed: onDetails,

                    style: TextButton.styleFrom(

                      minimumSize: Size.zero,

                      padding: compact ? EdgeInsets.symmetric(horizontal: ResponsiveMetrics.of(context).spacing(3)) : null,

                      tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,

                    ),

                    child: Text(

                      'See All',

                      style: TextStyle(fontSize: compact ? 9 : 14),

                    ),

                  ),

                ],

              );

            },

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(8)),

          if (data.upcoming.isEmpty)

            Padding(

              padding: EdgeInsets.symmetric(vertical: ResponsiveMetrics.of(context).h(10)),

              child: Align(

                alignment: Alignment.centerLeft,

                child: Text(

                  'You are all caught up.',

                  style: TextStyle(color: Color(0xFF7F8BA0), fontSize: ResponsiveMetrics.of(context).text(12)),

                ),

              ),

            )

          else

            _UpcomingActionGrid(

              actions: data.upcoming,

              onSeeAll: onDetails,

            ),

        ],

      ),

    );

  }

  static String _money(int minorUnits) => _formatMoneyMinor(minorUnits);

}

class _UpcomingActionGrid extends StatelessWidget {

  final List<ScheduledActionExecutionContext> actions;

  final VoidCallback onSeeAll;

  const _UpcomingActionGrid({

    required this.actions,

    required this.onSeeAll,

  });

  @override

  Widget build(BuildContext context) {

    final visible = actions.take(6).toList();

    return Column(

      children: [

        Wrap(

          spacing: 8,

          runSpacing: 8,

          children: [

            for (final action in visible)

              SizedBox(

                width: (MediaQuery.of(context).size.width - ResponsiveMetrics.of(context).spacing(82)) / 3,

                child: _DueMiniCard(action: action),

              ),

          ],

        ),

        if (actions.length > 6)

          Align(

            alignment: Alignment.centerRight,

            child: TextButton(

              onPressed: onSeeAll,

              child: const Text('See All  ›'),

            ),

          ),

      ],

    );

  }

}

class _DueMiniCard extends StatelessWidget {

  final ScheduledActionExecutionContext action;

  const _DueMiniCard({required this.action});

  Color get _color {

    switch (action.action.kind) {

      case ScheduledActionKind.expense:

      case ScheduledActionKind.liabilityPayment:

        return const Color(0xFFFF5265);

      case ScheduledActionKind.income:

        return const Color(0xFF19D89B);

      case ScheduledActionKind.goalContribution:

        return const Color(0xFF3A7BFF);

      case ScheduledActionKind.transfer:

        return const Color(0xFFFF2D8D);

      case ScheduledActionKind.investment:

        return const Color(0xFFFFB21A);

      case ScheduledActionKind.budgetReset:

        return const Color(0xFF9C4DFF);

    }

  }

  String _dueLabel(DateTime date) {

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final target = DateTime(date.year, date.month, date.day);

    final days = target.difference(today).inDays;

    if (days < 0) return 'Overdue';

    if (days == 0) return 'Today';

    if (days == 1) return 'Tomorrow';

    return 'In $days days';

  }

  @override

  Widget build(BuildContext context) {

    return Container(

      constraints: BoxConstraints(minHeight: ResponsiveMetrics.of(context).h(58)),

      padding: EdgeInsets.symmetric(horizontal: ResponsiveMetrics.of(context).spacing(7), vertical: ResponsiveMetrics.of(context).h(6)),

      decoration: BoxDecoration(

        color: _color.withValues(alpha: .055),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: _color.withValues(alpha: .16)),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            action.action.title,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(

              color: Colors.white,

              fontSize: ResponsiveMetrics.of(context).text(9.5),

              fontWeight: FontWeight.w700,

            ),

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(4)),

          Text(

            '${_formatMoneyMinor(_toMinor(action.action.amount))} EGP',

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(

              color: _color,

              fontSize: ResponsiveMetrics.of(context).text(11.5),

              fontWeight: FontWeight.w800,

            ),

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(2)),

          Text(

            _dueLabel(action.action.dueDate),

            style: TextStyle(

              color: Color(0xFF8B97AA),

              fontSize: ResponsiveMetrics.of(context).text(8),

            ),

          ),

        ],

      ),

    );

  }

}

class _OverviewMetric extends StatelessWidget {

  final IconData icon;

  final Color color;

  final String title;

  final String value;

  final String unit;

  final String subtitle;

  final bool compact;

  const _OverviewMetric({

    required this.icon,

    required this.color,

    required this.title,

    required this.value,

    required this.unit,

    required this.subtitle,

    this.compact = false,

  });

  @override

  Widget build(BuildContext context) {

    final metrics = ResponsiveMetrics.of(context);

    final horizontal = metrics.spacing(compact ? 3 : 8);

    final titleSize = metrics.text(compact ? 7.5 : 11);

    final valueSize = metrics.text(compact ? 17 : 22);

    final unitSize = metrics.text(compact ? 8 : 12);

    final subtitleSize = metrics.text(compact ? 7 : 10);

    final iconSize = metrics.size(compact ? 13 : 19);

    return Padding(

      padding: EdgeInsets.symmetric(horizontal: horizontal),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Row(

            children: [

              Icon(icon, color: color, size: iconSize),

              const SizedBox(width: 4),

              Expanded(

                child: Text(

                  title,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(

                    color: const Color(0xFFA9B3C7),

                    fontSize: titleSize,

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ),

            ],

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(compact ? 3 : 5)),

          FittedBox(

            fit: BoxFit.scaleDown,

            alignment: Alignment.centerLeft,

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [

                Text(

                  value,

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: valueSize,

                    fontWeight: FontWeight.w800,

                  ),

                ),

                const SizedBox(width: 3),

                Text(

                  unit,

                  style: TextStyle(

                    color: color,

                    fontSize: unitSize,

                    fontWeight: FontWeight.w800,

                  ),

                ),

              ],

            ),

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(compact ? 2 : 4)),

          Text(

            subtitle,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(

              color: const Color(0xFF7F8BA0),

              fontSize: subtitleSize,

            ),

          ),

        ],

      ),

    );

  }

}

class _VerticalDivider extends StatelessWidget {

  final bool compact;

  const _VerticalDivider({this.compact = false});

  @override

  Widget build(BuildContext context) {

    return Container(

      height: ResponsiveMetrics.of(context).h(compact ? 52 : 72),

      width: ResponsiveMetrics.of(context).size(1),

      color: Colors.white.withValues(alpha: .08),

    );

  }

}

class _SystemCard extends StatelessWidget {

  final Color color;

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  final int mustCount;

  final int needCount;

  final int wantCount;

  final int footerCount;

  final String footerLabel;

  final int footerAmount;

  final String footerAmountLabel;

  const _SystemCard({

    required this.color,

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.onTap,

    required this.mustCount,

    required this.needCount,

    required this.wantCount,

    required this.footerCount,

    required this.footerLabel,

    required this.footerAmount,

    required this.footerAmountLabel,

  });

  @override

  Widget build(BuildContext context) {

    return _Panel(

      borderColor: color.withValues(alpha: .38),

      padding: EdgeInsets.fromLTRB(ResponsiveMetrics.of(context).spacing(9), ResponsiveMetrics.of(context).h(10), ResponsiveMetrics.of(context).spacing(9), ResponsiveMetrics.of(context).h(9)),

      child: Column(

        children: [

          LayoutBuilder(

            builder: (context, constraints) {

              // These cards share a narrow row on phones. Keep the title on
              // one line so "Recurring" never breaks awkwardly.
              final compact = constraints.maxWidth < 180;

              final metrics = ResponsiveMetrics.of(context);

              final iconSize = metrics.size(compact ? 38 : 44);

              final titleSize = metrics.text(compact ? 13.5 : 15);

              final subtitleSize = metrics.text(compact ? 8.2 : 9);

              final actionSize = metrics.size(compact ? 24 : 28);

              return Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _IconBox(color: color, icon: icon, size: iconSize),

                  SizedBox(width: metrics.spacing(compact ? 8 : 11)),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        FittedBox(

                          fit: BoxFit.scaleDown,

                          alignment: Alignment.centerLeft,

                          child: Text(

                            title,

                            maxLines: 1,

                            softWrap: false,

                            style: TextStyle(

                              color: Colors.white,

                              fontSize: titleSize,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                        ),

                        SizedBox(height: metrics.h(3)),

                        Text(

                          subtitle,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(

                            color: Color(0xFFA9B3C7),

                            fontSize: subtitleSize,

                            height: 1.15,

                          ),

                        ),

                      ],

                    ),

                  ),

                  IconButton(

                    onPressed: onTap,

                    padding: EdgeInsets.zero,

                    constraints: BoxConstraints.tightFor(

                      width: actionSize,

                      height: metrics.h(compact ? 24 : 28),

                    ),

                    iconSize: metrics.size(compact ? 16 : 18),

                    icon: const Icon(

                      Icons.chevron_right_rounded,

                      color: Color(0xFFB8C2D6),

                    ),

                  ),

                ],

              );

            },

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(8)),

          LayoutBuilder(

            builder: (context, constraints) {

              final boxes = [

                _PriorityBox(

                  label: 'Must',

                  count: mustCount,

                  amount: mustCount == 0 ? 0 : footerAmount,

                  color: const Color(0xFFFF405A),

                ),

                _PriorityBox(

                  label: 'Need',

                  count: needCount,

                  amount: 0,

                  color: const Color(0xFFFFB11A),

                ),

                _PriorityBox(

                  label: 'Want',

                  count: wantCount,

                  amount: 0,

                  color: const Color(0xFF19D89B),

                ),

              ];

              return Row(

                children: [

                  Expanded(child: boxes[0]),

                  SizedBox(width: ResponsiveMetrics.of(context).spacing(6)),

                  Expanded(child: boxes[1]),

                  SizedBox(width: ResponsiveMetrics.of(context).spacing(6)),

                  Expanded(child: boxes[2]),

                ],

              );

            },

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(7)),

          Divider(color: Colors.white.withValues(alpha: .07), height: ResponsiveMetrics.of(context).h(1)),

          SizedBox(height: ResponsiveMetrics.of(context).h(6)),

          Row(

            children: [

              Text(

                '$footerCount',

                style: TextStyle(

                  color: color,

                  fontSize: ResponsiveMetrics.of(context).text(18),

                  fontWeight: FontWeight.w800,

                ),

              ),

              SizedBox(width: ResponsiveMetrics.of(context).spacing(6)),

              Text(

                footerLabel,

                style: TextStyle(

                  color: Color(0xFFA9B3C7),

                  fontSize: ResponsiveMetrics.of(context).text(9),

                ),

              ),

              const Spacer(),

              Column(

                crossAxisAlignment: CrossAxisAlignment.end,

                children: [

                  Text(

                    '${_formatMoneyMinor(footerAmount)} EGP',

                    style: TextStyle(

                      color: color,

                      fontSize: ResponsiveMetrics.of(context).text(13),

                      fontWeight: FontWeight.w800,

                    ),

                  ),

                  Text(

                    footerAmountLabel,

                    style: TextStyle(

                      color: Color(0xFFA9B3C7),

                      fontSize: ResponsiveMetrics.of(context).text(8),

                    ),

                  ),

                ],

              ),

            ],

          ),

        ],

      ),

    );

  }

}

class _PriorityBox extends StatelessWidget {

  final String label;

  final int count;

  final int amount;

  final Color color;

  const _PriorityBox({

    required this.label,

    required this.count,

    required this.amount,

    required this.color,

  });

  @override

  Widget build(BuildContext context) {

    return Container(

      // Do not force a fixed height here. On narrow phones the text
      // metrics can be a few pixels taller than the fixed box and Flutter
      // reports a bottom overflow. A minimum height preserves the design
      // without constraining the intrinsic content height.
      constraints: BoxConstraints(minHeight: ResponsiveMetrics.of(context).h(62)),

      padding: EdgeInsets.fromLTRB(ResponsiveMetrics.of(context).spacing(7), ResponsiveMetrics.of(context).h(7), ResponsiveMetrics.of(context).spacing(7), ResponsiveMetrics.of(context).h(5)),

      decoration: BoxDecoration(

        color: color.withValues(alpha: .07),

        borderRadius: BorderRadius.circular(4),

        border: Border.all(color: color.withValues(alpha: .24)),

      ),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Text(

            label,

            maxLines: 1,

            softWrap: false,

            style: TextStyle(

              color: color,

              fontSize: ResponsiveMetrics.of(context).text(11),

              fontWeight: FontWeight.w800,

            ),

          ),

          SizedBox(height: ResponsiveMetrics.of(context).h(5)),

          Text(

            '$count',

            style: TextStyle(

              color: Colors.white,

              fontSize: ResponsiveMetrics.of(context).text(19),

              fontWeight: FontWeight.w800,

            ),

          ),

          Text(

            '${_formatMoneyMinor(amount)} EGP',

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(

              color: color,

              fontSize: ResponsiveMetrics.of(context).text(9),

              fontWeight: FontWeight.w800,

            ),

          ),

        ],

      ),

    );

  }

}

class _WideSystemCard extends StatelessWidget {

  final Color color;

  final IconData icon;

  final String title;

  final String subtitle;

  final String metric;

  final String metricLabel;

  final String secondary;

  final VoidCallback onTap;

  const _WideSystemCard({

    required this.color,

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.metric,

    required this.metricLabel,

    required this.secondary,

    required this.onTap,

  });

  @override

  Widget build(BuildContext context) {

    return _Panel(

      borderColor: color.withValues(alpha: .16),

      padding: EdgeInsets.fromLTRB(ResponsiveMetrics.of(context).spacing(14), ResponsiveMetrics.of(context).h(13), ResponsiveMetrics.of(context).spacing(10), ResponsiveMetrics.of(context).h(13)),

      child: LayoutBuilder(

        builder: (context, constraints) {

          final compact = constraints.maxWidth < 430;

          final titleBlock = Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: ResponsiveMetrics.of(context).text(15),

                    fontWeight: FontWeight.w800,

                  ),

                ),

                SizedBox(height: ResponsiveMetrics.of(context).h(4)),

                Text(

                  subtitle,

                  maxLines: compact ? 2 : 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(

                    color: Color(0xFFA9B3C7),

                    fontSize: ResponsiveMetrics.of(context).text(9),

                  ),

                ),

              ],

            ),

          );

          final metricBlock = Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                metric,

                style: TextStyle(

                  color: color,

                  fontSize: ResponsiveMetrics.of(context).text(16),

                  fontWeight: FontWeight.w800,

                ),

              ),

              Text(

                metricLabel,

                style: TextStyle(

                  color: Color(0xFFA9B3C7),

                  fontSize: ResponsiveMetrics.of(context).text(8),

                ),

              ),

              SizedBox(height: ResponsiveMetrics.of(context).h(2)),

              Text(

                secondary,

                style: TextStyle(

                  color: Color(0xFF7F8BA0),

                  fontSize: ResponsiveMetrics.of(context).text(10),

                ),

              ),

            ],

          );

          if (compact) {

            return Row(

              children: [

                _IconBox(color: color, icon: icon, size: ResponsiveMetrics.of(context).size(44)),

                SizedBox(width: ResponsiveMetrics.of(context).spacing(11)),

                titleBlock,

                SizedBox(width: ResponsiveMetrics.of(context).spacing(8)),

                metricBlock,

                IconButton(

                  onPressed: onTap,

                  icon: const Icon(

                    Icons.chevron_right_rounded,

                    color: Color(0xFFB8C2D6),

                  ),

                ),

              ],

            );

          }

          return Row(

            children: [

              _IconBox(color: color, icon: icon, size: ResponsiveMetrics.of(context).size(52)),

              SizedBox(width: ResponsiveMetrics.of(context).spacing(13)),

              titleBlock,

              SizedBox(width: ResponsiveMetrics.of(context).spacing(8)),

              Container(

                width: ResponsiveMetrics.of(context).size(1),

                height: ResponsiveMetrics.of(context).h(54),

                color: Colors.white.withValues(alpha: .07),

              ),

              SizedBox(width: ResponsiveMetrics.of(context).spacing(14)),

              metricBlock,

              IconButton(

                onPressed: onTap,

                icon: const Icon(

                  Icons.chevron_right_rounded,

                  color: Color(0xFFB8C2D6),

                ),

              ),

            ],

          );

        },

      ),

    );

  }

}

class _IconBox extends StatelessWidget {

  final Color color;

  final IconData icon;

  final double size;

  const _IconBox({

    required this.color,

    required this.icon,

    required this.size,

  });

  @override

  Widget build(BuildContext context) {

    return Container(

      width: size,

      height: size,

      decoration: BoxDecoration(

        color: color.withValues(alpha: .16),

        borderRadius: BorderRadius.circular(4),

        border: Border.all(color: color.withValues(alpha: .22)),

      ),

      child: Icon(icon, color: color, size: size * .48),

    );

  }

}

class _Panel extends StatelessWidget {

  final Widget child;

  final EdgeInsets padding;

  final Color borderColor;

  const _Panel({

    required this.child,

    this.padding = const EdgeInsets.all(14),

    this.borderColor = const Color(0xFF1C3048),

  });

  @override

  Widget build(BuildContext context) {

    return Container(

      padding: padding,

      decoration: BoxDecoration(

        color: const Color(0xFF071421).withValues(alpha: .94),

        borderRadius: BorderRadius.circular(5),

        border: Border.all(color: borderColor),

        boxShadow: const [

          BoxShadow(

            color: Color(0x44000000),

            blurRadius: 20,

            offset: Offset(0, 8),

          ),

        ],

      ),

      child: child,

    );

  }

}

class _ErrorState extends StatelessWidget {

  final String message;

  final Future<void> Function() onRetry;

  const _ErrorState({

    required this.message,

    required this.onRetry,

  });

  @override

  Widget build(BuildContext context) {

    return Center(

      child: Padding(

        padding: EdgeInsets.all(ResponsiveMetrics.of(context).spacing(28)),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            const Icon(

              Icons.error_outline_rounded,

              color: Colors.orange,

              size: 44,

            ),

            SizedBox(height: ResponsiveMetrics.of(context).h(12)),

            Text(
              'Could not load Manage',

              style: TextStyle(

                color: Colors.white,

                fontSize: ResponsiveMetrics.of(context).text(18),

                fontWeight: FontWeight.w800,

              ),

            ),

            SizedBox(height: ResponsiveMetrics.of(context).h(6)),

            Text(

              message,

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.white54),

            ),

            SizedBox(height: ResponsiveMetrics.of(context).h(16)),

            FilledButton(

              onPressed: onRetry,

              child: const Text('Retry'),

            ),

          ],

        ),

      ),

    );

  }

}
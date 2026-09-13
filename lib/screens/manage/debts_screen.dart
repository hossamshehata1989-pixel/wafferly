import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/money/money.dart';
import '../../models/account.dart';
import '../../models/commitment.dart';
import '../../models/debt/debt_summary.dart';
import '../../models/enums/commitment_status.dart';
import '../../models/enums/commitment_type.dart';
import '../../models/enums/schedule_occurrence_status.dart';
import '../../models/schedule_occurrence.dart';
import '../../models/schedule_rule.dart';
import '../../services/balance_service.dart';
import '../../services/debt_query_service.dart';
import '../accounts/account_details_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DebtsView();
  }
}

class _DebtsView extends StatefulWidget {
  const _DebtsView();

  @override
  State<_DebtsView> createState() => _DebtsViewState();
}

class _DebtsViewState extends State<_DebtsView> {
  late final DebtQueryService _queryService;

  Box<Account> get _accountBox => Hive.box<Account>('accounts');

  Box<Commitment> get _commitmentBox =>
      Hive.box<Commitment>('commitments');

  Box<ScheduleRule> get _scheduleRuleBox =>
      Hive.box<ScheduleRule>('schedule_rules');

  Box<ScheduleOccurrence> get _occurrenceBox =>
      Hive.box<ScheduleOccurrence>('schedule_occurrences');

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
  return AnimatedBuilder(
    animation: Listenable.merge([
      _accountBox.listenable(),
      _commitmentBox.listenable(),
      _scheduleRuleBox.listenable(),
      _occurrenceBox.listenable(),
    ]),
    builder: (context, _) {
      return _buildScreen(context);
    },
  );
}

  Widget _buildScreen(BuildContext context) {
    final now = DateTime.now();

    final summaries = _queryService.getDebtSummaries(
      today: now,
    );

    final totalOutstanding = summaries.fold<Money>(
      Money.zero,
      (sum, item) => sum + item.outstanding,
    );

    final thisMonth = _calculateThisMonth(
      now,
      summaries,
    );

    final overdue = _calculateState(
      summaries,
      now,
      _DebtStateFilter.overdue,
    );

    final dueSoon = _calculateState(
      summaries,
      now,
      _DebtStateFilter.dueSoon,
    );

    final upcoming = _calculateState(
      summaries,
      now,
      _DebtStateFilter.upcoming,
    );

    final categories = _buildCategories(
      summaries,
      now,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020914),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 82,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All your liabilities in one place.',
              style: TextStyle(
                color: Color(0xFFB8C8E6),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF3A7BFF),
          backgroundColor: const Color(0xFF07182A),
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              28,
            ),
            children: [
              _SummaryCard(
                totalOutstanding: totalOutstanding.toDouble(),
                thisMonth: thisMonth,
                categories: categories,
                overdueCount: overdue.count,
                overdueAmount: overdue.amount,
                dueSoonCount: dueSoon.count,
                dueSoonAmount: dueSoon.amount,
                upcomingCount: upcoming.count,
                upcomingAmount: upcoming.amount,
              ),

              const SizedBox(height: 18),

              _CategoryGrid(
                categories: categories,
                onTap: (category) {
                  if (category.accounts.isEmpty) {
                    return;
                  }

                  _openCategory(
                    context,
                    category,
                  );
                },
              ),

              const SizedBox(height: 18),

              _ProgressCard(
                totalOutstanding: totalOutstanding.toDouble(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DebtCategory> _buildCategories(
    List<DebtSummary> summaries,
    DateTime today,
  ) {
    return [
      _createCategory(
        title: 'Loans',
        shortTitle: 'Loans',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF08C7F8),
        type: 'loan',
        summaries: summaries,
        today: today,
        countLabel: 'loans',
      ),
      _createCategory(
        title: 'Credit Cards',
        shortTitle: 'Credit Cards',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFFFF2D6F),
        type: 'creditCard',
        summaries: summaries,
        today: today,
        countLabel: 'cards',
      ),
      _createCategory(
        title: 'Installment Companies',
        shortTitle: 'Installments',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFFFFB000),
        type: 'installment',
        summaries: summaries,
        today: today,
        countLabel: 'accounts',
      ),
      _createCategory(
        title: 'Borrowed Money',
        shortTitle: 'Borrowed',
        icon: Icons.person_rounded,
        color: const Color(0xFF00E3A8),
        type: 'debt',
        summaries: summaries,
        today: today,
        countLabel: 'people',
      ),
      _createInactiveCategory(
        title: 'Temporary Debt',
        shortTitle: 'Temporary',
        icon: Icons.access_time_rounded,
        color: const Color(0xFF8EA8D6),
        countLabel: 'items',
      ),
      _createInactiveCategory(
        title: 'Rotating Savings (Collection)',
        shortTitle: 'Rotating',
        icon: Icons.groups_rounded,
        color: const Color(0xFF7F9CCF),
        countLabel: 'collections',
      ),
    ];
  }

  _DebtCategory _createCategory({
    required String title,
    required String shortTitle,
    required IconData icon,
    required Color color,
    required String type,
    required List<DebtSummary> summaries,
    required DateTime today,
    required String countLabel,
  }) {
    final matching = summaries
        .where((summary) => summary.liabilityAccount.type == type)
        .toList();

    final outstanding = matching.fold<double>(
      0,
      (sum, item) => sum + item.outstanding.toDouble(),
    );

    final thisMonth = matching.fold<double>(
      0,
      (sum, item) =>
          sum +
          _thisMonthForAccount(
            item.liabilityAccount.id,
            today,
          ),
    );

    return _DebtCategory(
      title: title,
      shortTitle: shortTitle,
      icon: icon,
      color: color,
      accounts: matching.map((e) => e.liabilityAccount).toList(),
      outstanding: outstanding,
      thisMonth: thisMonth,
      countLabel: countLabel,
      inactive: matching.isEmpty,
    );
  }

  _DebtCategory _createInactiveCategory({
    required String title,
    required String shortTitle,
    required IconData icon,
    required Color color,
    required String countLabel,
  }) {
    return _DebtCategory(
      title: title,
      shortTitle: shortTitle,
      icon: icon,
      color: color,
      accounts: const [],
      outstanding: 0,
      thisMonth: 0,
      countLabel: countLabel,
      inactive: true,
    );
  }

  double _thisMonthForAccount(
    String accountId,
    DateTime today,
  ) {
    double total = 0;

    for (final commitment in _commitmentBox.values) {
      if (commitment.isArchived ||
          commitment.status != CommitmentStatus.active ||
          commitment.type != CommitmentType.liabilityPayment ||
          commitment.liabilityAccountId != accountId) {
        continue;
      }

      final rule = _scheduleRuleBox.get(
        commitment.scheduleRuleId,
      );

      if (rule == null) {
        continue;
      }

      final dueDate = rule.nextDueDate;

      final isThisMonth =
          dueDate.year == today.year &&
          dueDate.month == today.month;

      if (!isThisMonth) {
        continue;
      }

      final occurrence = _occurrenceBox.get(
        ScheduleOccurrence.idFor(
          scheduleRuleId: rule.id,
          dueDate: dueDate,
        ),
      );

      if (occurrence?.status ==
          ScheduleOccurrenceStatus.completed) {
        continue;
      }

      total += commitment.amount.toDouble();
    }

    return total;
  }

  _DebtStateTotals _calculateState(
    List<DebtSummary> summaries,
    DateTime today,
    _DebtStateFilter filter,
  ) {
    int count = 0;
    double amount = 0;

    for (final summary in summaries) {
      final payment = summary.nextPayment;
      final rule = summary.scheduleRule;

      if (payment == null || rule == null) {
        continue;
      }

      final dueDate = DateTime(
        rule.nextDueDate.year,
        rule.nextDueDate.month,
        rule.nextDueDate.day,
      );

      final currentDate = DateTime(
        today.year,
        today.month,
        today.day,
      );

      final difference =
          dueDate.difference(currentDate).inDays;

      bool matches = false;

      switch (filter) {
        case _DebtStateFilter.overdue:
          matches = difference < 0;
          break;

        case _DebtStateFilter.dueSoon:
          matches = difference >= 0 && difference <= 7;
          break;

        case _DebtStateFilter.upcoming:
          matches = difference > 7;
          break;
      }

      if (!matches) {
        continue;
      }

      count++;
      amount += payment.amount.toDouble();
    }

    return _DebtStateTotals(
      count: count,
      amount: amount,
    );
  }

  double _calculateThisMonth(
    DateTime today,
    List<DebtSummary> summaries,
  ) {
    double total = 0;

    for (final summary in summaries) {
      total += _thisMonthForAccount(
        summary.liabilityAccount.id,
        today,
      );
    }

    return total;
  }

  void _openCategory(
    BuildContext context,
    _DebtCategory category,
  ) {
    if (category.accounts.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountDetailsScreen(
            accountId: category.accounts.first.id,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF07182A),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24,
            ),
            children: [
              Text(
                category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...category.accounts.map(
                (account) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _IconBubble(
                    icon: category.icon,
                    color: category.color,
                  ),
                  title: Text(
                    account.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountDetailsScreen(
                          accountId: account.id,
                        ),
                      ),
                    );
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

enum _DebtStateFilter {
  overdue,
  dueSoon,
  upcoming,
}

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
  final String shortTitle;
  final IconData icon;
  final Color color;
  final List<Account> accounts;
  final double outstanding;
  final double thisMonth;
  final String countLabel;
  final bool inactive;

  const _DebtCategory({
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.color,
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

  final int overdueCount;
  final double overdueAmount;

  final int dueSoonCount;
  final double dueSoonAmount;

  final int upcomingCount;
  final double upcomingAmount;

  const _SummaryCard({
    required this.totalOutstanding,
    required this.thisMonth,
    required this.categories,
    required this.overdueCount,
    required this.overdueAmount,
    required this.dueSoonCount,
    required this.dueSoonAmount,
    required this.upcomingCount,
    required this.upcomingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final activeCategories = categories
        .where((category) => category.outstanding > 0)
        .toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF082441),
            Color(0xFF061629),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF007BBD),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008CFF).withOpacity(0.14),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        16,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Outstanding',
                      style: TextStyle(
                        color: Color(0xFFB7C8E7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _AmountText(
                      amount: totalOutstanding,
                      fontSize: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This Month',
                      style: TextStyle(
                        color: Color(0xFFB7C8E7),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _AmountText(
                      amount: thisMonth,
                      fontSize: 24,
                      color: const Color(0xFF00B9FF),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.north_east_rounded,
                          color: Color(0xFFFF2D6F),
                          size: 22,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '12%',
                          style: TextStyle(
                            color: Color(0xFFFF2D6F),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'vs last month',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _DebtDonut(
                  categories: activeCategories,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(
            color: Color(0xFF27405D),
            height: 1,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StateMetric(
                  count: overdueCount,
                  label: 'Overdue',
                  amount: overdueAmount,
                  color: const Color(0xFFFF2D6F),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _StateMetric(
                  count: dueSoonCount,
                  label: 'Due Soon',
                  amount: dueSoonAmount,
                  color: const Color(0xFFFFB000),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _StateMetric(
                  count: upcomingCount,
                  label: 'Upcoming',
                  amount: upcomingAmount,
                  color: const Color(0xFF00AFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtDonut extends StatelessWidget {
  final List<_DebtCategory> categories;

  const _DebtDonut({
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(
      0,
      (sum, item) => sum + item.outstanding,
    );

    return SizedBox(
      width: 150,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(138, 138),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'types',
                style: TextStyle(
                  color: Color(0xFFB7C8E7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(size.width, size.height) / 2 - 7;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.butt;

    if (total <= 0) {
      paint.color = const Color(0xFF20344F);
      canvas.drawCircle(
        center,
        radius,
        paint,
      );
      return;
    }

    double startAngle = -math.pi / 2;

    for (final category in categories) {
      if (category.outstanding <= 0) {
        continue;
      }

      final sweep =
          (category.outstanding / total) * math.pi * 2;

      paint.color = category.color;

      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.categories != categories;
  }
}

class _StateMetric extends StatelessWidget {
  final int count;
  final String label;
  final double amount;
  final Color color;

  const _StateMetric({
    required this.count,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFB7C8E7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatAmount(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
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

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFF3C516D),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<_DebtCategory> categories;
  final ValueChanged<_DebtCategory> onTap;

  const _CategoryGrid({
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.20,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return _DebtCategoryCard(
          category: category,
          onTap: () => onTap(category),
        );
      },
    );
  }
}

class _DebtCategoryCard extends StatelessWidget {
  final _DebtCategory category;
  final VoidCallback onTap;

  const _DebtCategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = category.inactive;

    final borderColor = inactive
        ? const Color(0xFF344A68)
        : category.color;

    final backgroundColor = inactive
        ? const Color(0xFF101F35)
        : Color.lerp(
            const Color(0xFF071629),
            category.color,
            0.12,
          )!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: inactive ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: inactive
                ? null
                : [
                    BoxShadow(
                      color: category.color.withOpacity(0.10),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          padding: const EdgeInsets.fromLTRB(
            14,
            14,
            12,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBubble(
                    icon: category.icon,
                    color: category.color,
                    inactive: inactive,
                  ),
                  const Spacer(),
                  if (!inactive)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 25,
                    )
                  else
                    const _InactiveBadge(),
                ],
              ),
              const Spacer(),
              Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: inactive
                      ? const Color(0xFF9FB2D4)
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      _formatAmount(
                        category.outstanding,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: inactive
                            ? Colors.white
                            : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (!inactive) ...[
                const SizedBox(height: 3),
                Text(
                  'This Month',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatAmount(
                    category.thisMonth,
                  ),
                  style: TextStyle(
                    color: category.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 3),
                const Text(
                  'This Month',
                  style: TextStyle(
                    color: Color(0xFF9FB2D4),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '0 EGP',
                  style: TextStyle(
                    color: category.color.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                inactive
                    ? 'No active items'
                    : '${category.accounts.length} ${category.countLabel}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool inactive;

  const _IconBubble({
    required this.icon,
    required this.color,
    this.inactive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: inactive
            ? const Color(0xFF243754)
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: inactive
            ? const Color(0xFF9BB0D7)
            : color,
        size: 26,
      ),
    );
  }
}

class _InactiveBadge extends StatelessWidget {
  const _InactiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF38506F),
        ),
      ),
      child: const Text(
        'Inactive',
        style: TextStyle(
          color: Color(0xFF9DB3D8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final Color color;

  const _AmountText({
    required this.amount,
    required this.fontSize,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: _formatNumber(amount),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: ' EGP',
            style: TextStyle(
              color: color,
              fontSize: fontSize * 0.55,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double totalOutstanding;

  const _ProgressCard({
    required this.totalOutstanding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101A72),
            Color(0xFF27106B),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6B25FF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF5A27A5).withOpacity(0.30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFFC05CFF),
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're doing well!",
                  style: TextStyle(
                    color: Color(0xFFE05CFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your total debt decreased by 12% this month.',
                  style: TextStyle(
                    color: Color(0xFFD3DDF1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 27,
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
    if (i > 0 &&
        (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[i]);
  }

  return buffer.toString();
}

String _formatAmount(double value) {
  return '${_formatNumber(value)} EGP';
}
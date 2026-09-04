import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/planning/engine/planning_engine.dart';
import '../../core/planning/operations/release_operation.dart';
import '../../core/planning/value_objects/planning_source_type.dart';
import '../../models/goal_activity.dart';
import '../../services/goal_activity_service.dart';
import '../../services/reserved_money_projection_service.dart';
import '../../models/reserved_money_projection.dart';

/// Global Reserved Money management screen.
///
/// CURRENT reservations are read from the Planning Engine allocation
/// projection and releases are executed through the Planning Engine.
class ReservedMoneyScreen extends StatefulWidget {
  const ReservedMoneyScreen({super.key});

  @override
  State<ReservedMoneyScreen> createState() => _ReservedMoneyScreenState();
}

class _ReservedMoneyScreenState extends State<ReservedMoneyScreen> {
  late final ReservedMoneyProjectionService _projectionService;
  late final PlanningEngine _planningEngine;
  final GoalActivityService _goalActivityService = GoalActivityService();

  ReservedMoneyProjection? _projection;
  bool _loading = true;
  String? _error;
  String? _releasingAllocationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _projectionService = context.read<ReservedMoneyProjectionService>();
    _planningEngine = context.read<PlanningEngine>();
    if (_projection == null && _loading) {
      _loadProjection();
    }
  }

  Future<void> _loadProjection() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projection = await _projectionService.getProjection();
      if (!mounted) return;
      setState(() {
        _projection = projection;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load reserved money right now.';
      });
    }
  }

  Future<void> _release(ReservedMoneyItem item) async {
    if (_releasingAllocationId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Release Reserved Money'),
        content: Text(
          'Release ${_money(item.amount)} EGP from "${item.sourceName}"?\n\n'
          'The money will become available in ${item.accountName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Reserved'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Release'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _releasingAllocationId = item.allocationId);

    try {
      final operation = ReleaseOperation(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        sourceId: item.sourceId,
        sourceType: _sourceTypeFromName(item.sourceType),
        accountId: item.accountId,
        amount: item.amount,
      );

      await _planningEngine.execute(operation);

      // Goal release is also a GoalActivity because that is the goal's
      // financial history/event record. Other planning sources do not have
      // a GoalActivity stream.
      if (item.sourceType == 'goal') {
        await _goalActivityService.addActivity(
          GoalActivity.create(
            goalId: item.sourceId,
            type: GoalActivityType.release,
            amount: item.amount,
            sourceAccountId: item.accountId,
            notes: 'Released from Reserved Money screen',
          ),
        );
      }

      await _loadProjection();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_money(item.amount)} EGP released successfully',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _releasingAllocationId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to release this reservation.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _releasingAllocationId = null);
      }
    }
  }

  PlanningSourceType _sourceTypeFromName(String value) {
    for (final type in PlanningSourceType.values) {
      if (type.name == value) return type;
    }
    throw ArgumentError('Unsupported planning source type: $value');
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final projection = _projection;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600 ? 16.0 : 28.0;
    final maxWidth = width >= 1100 ? 1100.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF07111D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reserved Money',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadProjection,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _buildBody(projection, horizontal),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ReservedMoneyProjection? projection, double horizontal) {
    if (_loading && projection == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && projection == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadProjection,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final data = projection!;

    return RefreshIndicator(
      onRefresh: _loadProjection,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 32),
        children: [
          _buildSummaryCard(data),
          const SizedBox(height: 16),
          if (data.items.isEmpty)
            _buildEmptyState()
          else ...[
            _buildAccountSummary(data),
            const SizedBox(height: 16),
            _buildReservations(data),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ReservedMoneyProjection data) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142438), Color(0xFF0D1727)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFAA2C).withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFFFAA2C),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Reserved',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_money(data.totalReserved)} EGP',
                  style: const TextStyle(
                    color: Color(0xFFFFAA2C),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.items.length} active reservation${data.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary(ReservedMoneyProjection data) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.account_balance_wallet_outlined,
            title: 'By Account',
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < data.accounts.length; i++) ...[
            _AccountRow(summary: data.accounts[i]),
            if (i < data.accounts.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildReservations(ReservedMoneyProjection data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Reserved Allocations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (final category in data.categories) ...[
          _CategoryPanel(
            category: category,
            onRelease: _release,
            releasingAllocationId: _releasingAllocationId,
            money: _money,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Colors.white38,
                size: 29,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No reserved money',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Money reserved through the Planning Engine will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPanel extends StatelessWidget {
  const _CategoryPanel({
    required this.category,
    required this.onRelease,
    required this.releasingAllocationId,
    required this.money,
  });

  final ReservedMoneyCategory category;
  final ValueChanged<ReservedMoneyItem> onRelease;
  final String? releasingAllocationId;
  final String Function(double) money;

  IconData get _icon {
    switch (category.key) {
      case 'goal':
        return Icons.flag_outlined;
      case 'budget':
        return Icons.account_balance_outlined;
      case 'manual':
        return Icons.bookmark_border_rounded;
      case 'commitment':
        return Icons.event_note_outlined;
      default:
        return Icons.lock_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 2, bottom: 9),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFAA2C).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: const Color(0xFFFFAA2C), size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .045),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${category.items.length} ${category.items.length == 1 ? 'reservation' : 'reservations'}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // IMPORTANT: every Allocation is rendered as its own card.
        // There is intentionally no merge by source, account, or amount.
        for (int i = 0; i < category.items.length; i++) ...[
          _ReservationCard(
            item: category.items[i],
            index: i + 1,
            onRelease: onRelease,
            releasing: releasingAllocationId == category.items[i].allocationId,
            money: money,
          ),
          if (i < category.items.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.item,
    required this.index,
    required this.onRelease,
    required this.releasing,
    required this.money,
  });

  final ReservedMoneyItem item;
  final int index;
  final ValueChanged<ReservedMoneyItem> onRelease;
  final bool releasing;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1827),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: .065)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF9B6CFF).withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFFB995FF),
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.sourceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${money(item.amount)} EGP',
                      style: const TextStyle(
                        color: Color(0xFFFFAA2C),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _MetaLine(
                  icon: Icons.account_balance_wallet_outlined,
                  text: item.accountName,
                ),
                const SizedBox(height: 4),
                _MetaLine(
                  icon: Icons.schedule_outlined,
                  text: _dateTime(item.createdAt),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .035),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Reservation #$index',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: releasing ? null : () => onRelease(item),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: releasing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open_rounded, size: 15),
                      label: const Text('Release'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateTime(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white30, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.summary});

  final ReservedMoneyAccountSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white54,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary.accountName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${summary.reserved == summary.reserved.roundToDouble() ? summary.reserved.toStringAsFixed(0) : summary.reserved.toStringAsFixed(2)} EGP',
            style: const TextStyle(
              color: Color(0xFFFFAA2C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1827),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

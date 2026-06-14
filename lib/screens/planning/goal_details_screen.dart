// lib/screens/planning/goal_details_screen.dart

import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../../services/goal_projection_service.dart';
import 'widgets/goal_progress_card.dart';
import 'widgets/goal_action_tile.dart';
import 'dialogs/reserve_goal_dialog.dart';
import '../../services/goal_activity_service.dart';
import '../../models/goal_activity.dart';
import '../../services/account_service.dart';
import '../../services/goal_funding_projection_service.dart';
import '../../models/goal_funding_source.dart';
import 'dialogs/release_goal_dialog.dart';
import '../../services/goal_allocation_service.dart';
import 'dialogs/cancel_goal_dialog.dart';
import '../../services/goal_service.dart';
import '../../models/enums/goal_status.dart';
import 'dialogs/complete_goal_dialog.dart';
import 'dialogs/transfer_to_saving_dialog.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  late final GoalProjectionService _projectionService;
  late final GoalAllocationService _goalAllocationService;
  late final GoalActivityService _activityService;
  late final GoalFundingProjectionService _fundingProjectionService;
  late final GoalService _goalService;
  List<GoalFundingSource> _fundingSources = [];

  double _saved = 0.0;
  double _progress = 0.0;

  List<GoalActivity> _activities = [];

  @override
  void initState() {
    super.initState();

    _projectionService = GoalProjectionService();
    _activityService = GoalActivityService();

    _goalAllocationService = GoalAllocationService();

    _fundingProjectionService = GoalFundingProjectionService();
    _goalService = GoalService();

    _loadData();
  }

  Future<void> _loadData() async {
    final projection = await _fundingProjectionService.getProjection(
      widget.goal.id,
    );

    debugPrint('===================');
    debugPrint('PROJECTION TEST');
    debugPrint('Reserved: ${projection.totalReserved}');
    debugPrint('Saved: ${projection.totalSaved}');
    debugPrint('Progress: ${projection.totalProgress}');
    debugPrint('===================');

    final activities = _activityService.getGoalActivities(widget.goal.id);
    final fundingSources = _fundingProjectionService.getFundingSources(
      widget.goal.id,
    );

    setState(() {
      _saved = projection.totalProgress;

      _progress = widget.goal.targetAmount > 0
          ? (projection.totalProgress / widget.goal.targetAmount).clamp(
              0.0,
              1.0,
            )
          : 0.0;

      _activities = activities;

      _fundingSources = fundingSources;
    });
  }

  Future<void> _reserveMoney() async {
    final success = await showReserveGoalDialog(
      context,
      goalId: widget.goal.id,
    );
    if (success == true) {
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Money reserved successfully')),
      );
    } else if (success == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough available balance')),
      );
    }
  }

  Future<void> _transferToSaving() async {
    double totalReserved = 0;

    for (final source in _fundingSources) {
      totalReserved += source.amount;
    }

    await showTransferToSavingDialog(context, availableAmount: totalReserved);
  }

  Future<void> _transferFundingSource(GoalFundingSource source) async {
    await showTransferToSavingDialog(context, availableAmount: source.amount);
  }

  Future<void> _releaseReservation() async {
    double total = 0;

    for (final source in _fundingSources) {
      total += source.amount;
    }

    final confirm = await showReleaseGoalDialog(context, totalAmount: total);

    if (confirm != true) {
      return;
    }

    await _goalAllocationService.releaseGoal(widget.goal.id);

    for (final source in _fundingSources) {
      await _activityService.addActivity(
        GoalActivity.create(
          goalId: widget.goal.id,
          type: 'release',
          amount: source.amount,
          sourceAccountId: source.accountId,
        ),
      );
    }

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Goal released successfully')));
  }

  Future<void> _releaseFundingSource(GoalFundingSource source) async {
    final confirm = await showReleaseGoalDialog(
      context,
      totalAmount: source.amount,
    );

    if (confirm != true) {
      return;
    }

    await _goalAllocationService.releaseGoal(widget.goal.id);

    await _activityService.addActivity(
      GoalActivity.create(
        goalId: widget.goal.id,
        type: 'release',
        amount: source.amount,
        sourceAccountId: source.accountId,
      ),
    );

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${source.accountName} released successfully')),
    );
  }

  Future<void> _cancelGoal() async {
    final fundingSources = _fundingProjectionService.getFundingSources(
      widget.goal.id,
    );

    final totalAmount = fundingSources.fold<double>(
      0,
      (sum, source) => sum + source.amount,
    );

    final confirm = await showCancelGoalDialog(
      context,
      fundingSources: fundingSources,
    );

    if (confirm != true) {
      return;
    }

    await _goalAllocationService.releaseGoal(widget.goal.id);

    for (final source in fundingSources) {
      await _activityService.addActivity(
        GoalActivity.create(
          goalId: widget.goal.id,
          type: 'cancel',
          amount: source.amount,
          sourceAccountId: source.accountId,
        ),
      );
    }

    await _goalService.update(
      widget.goal.copyWith(status: GoalStatus.cancelled),
    );

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal cancelled successfully')),
    );
  }

  Future<void> _completeGoal() async {
    final action = await showCompleteGoalDialog(context);

    if (action == null) {
      return;
    }

    if (action == 'keep') {
      await _markGoalCompleted();

      await _activityService.addActivity(
        GoalActivity.create(
          goalId: widget.goal.id,
          type: 'completed_reserved',
          amount: _saved,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal completed successfully')),
      );
    }

    if (action == 'release') {
      await _goalAllocationService.releaseGoal(widget.goal.id);

      await _markGoalCompleted();

      for (final source in _fundingSources) {
        await _activityService.addActivity(
          GoalActivity.create(
            goalId: widget.goal.id,
            type: 'completed_release',
            amount: source.amount,
            sourceAccountId: source.accountId,
          ),
        );
      }

      await _loadData();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal completed and funds released')),
      );

      return;
    }
  }

  Future<void> _markGoalCompleted() async {
    final updatedGoal = widget.goal.copyWith(status: GoalStatus.completed);

    await _goalService.update(updatedGoal);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.goal.status == GoalStatus.completed;

    final isCancelled = widget.goal.status == GoalStatus.cancelled;
    final hasReleasedCompletion = _activities.any(
      (a) => a.type == 'completed_release',
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('Goal Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Goal - Coming Soon')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoalProgressCard(
              title: widget.goal.title,
              saved: _saved,
              target: widget.goal.targetAmount,
              progress: _progress,
              type: widget.goal.type,
            ),
            const SizedBox(height: 20),
            if (!isCompleted && !isCancelled && _progress < 1.0)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _reserveMoney,
                      icon: const Icon(Icons.add),
                      label: const Text('Reserve Money'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelGoal,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Goal'),
                    ),
                  ),
                ],
              ),
            if (!isCompleted && !isCancelled && _progress >= 1.0)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _completeGoal,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Goal'),
                ),
              ),
            const SizedBox(height: 32),

            if (!hasReleasedCompletion) ...[
              // Funding Sources Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Funding Sources',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_fundingSources.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_fundingSources.length} source${_fundingSources.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12, width: 0.5),
                ),
                child: _fundingSources.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No funding yet',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < _fundingSources.length; i++)
                            Column(
                              children: [
                                _buildFundingSourceTile(_fundingSources[i]),
                                if (i < _fundingSources.length - 1)
                                  const Divider(
                                    height: 0,
                                    thickness: 0.5,
                                    color: Colors.white12,
                                  ),
                              ],
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),
            ],
            // Goal Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Goal Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_activities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_activities.length} event${_activities.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12, width: 0.5),
              ),
              child: _activities.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No activity yet',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < _activities.length; i++)
                          Column(
                            children: [
                              _buildActivityTile(_activities[i]),
                              if (i < _activities.length - 1)
                                const Divider(
                                  height: 0,
                                  thickness: 0.5,
                                  color: Colors.white12,
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFundingSourceTile(GoalFundingSource source) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reserved',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${source.amount.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => _transferFundingSource(source),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Transfer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _releaseFundingSource(source),
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text('Release'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(GoalActivity activity) {
    final accountService = AccountService();
    final account = activity.sourceAccountId == null
        ? null
        : accountService.getAccountById(activity.sourceAccountId!);

    final icon = activity.type == 'reserve'
        ? Icons.lock
        : activity.type == 'release'
        ? Icons.lock_open
        : activity.type == 'cancel'
        ? Icons.cancel
        : activity.type == 'completed_reserved'
        ? Icons.check_circle
        : activity.type == 'completed_release'
        ? Icons.check_circle
        : Icons.history;

    final color = activity.type == 'reserve'
        ? Colors.orange
        : activity.type == 'release'
        ? Colors.green
        : activity.type == 'cancel'
        ? Colors.red
        : activity.type == 'completed_reserved'
        ? Colors.blue
        : activity.type == 'completed_release'
        ? Colors.green
        : Colors.grey;

    final title = activity.type == 'reserve'
        ? 'Reserved'
        : activity.type == 'release'
        ? 'Released'
        : activity.type == 'cancel'
        ? 'Cancelled'
        : activity.type == 'completed_reserved'
        ? 'Completed'
        : activity.type == 'completed_release'
        ? 'Completed & Released'
        : activity.type;

    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title ${activity.amount.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                if (account != null)
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

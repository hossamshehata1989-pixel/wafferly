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

    _loadData();
  }

  Future<void> _loadData() async {
    final allocated = await _projectionService.getGoalAllocatedAmount(
      widget.goal.id,
    );

    final activities = _activityService.getGoalActivities(widget.goal.id);
    final fundingSources = _fundingProjectionService.getFundingSources(
      widget.goal.id,
    );

    setState(() {
      _saved = allocated;

      _progress = widget.goal.targetAmount > 0
          ? (allocated / widget.goal.targetAmount).clamp(0.0, 1.0)
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

  void _transferToSaving() {
    // TODO: تنفيذ التحويل إلى حساب Saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer to saving coming soon')),
    );
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

  void _archiveGoal() {
    // TODO: تنفيذ أرشفة الهدف
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Archive goal coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('Goal Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 32),

            const Text(
              'Funding Sources',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _fundingSources.isEmpty
                  ? const Text(
                      'No funding yet',
                      style: TextStyle(color: Colors.white54),
                    )
                  : Column(
                      children: _fundingSources.map((source) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  source.accountName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),

                              Text(
                                '${source.amount.toStringAsFixed(0)} EGP',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Goal Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            _activities.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No activity yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : Column(
                    children: _activities.map((activity) {
                      final accountService = AccountService();

                      final account = activity.sourceAccountId == null
                          ? null
                          : accountService.getAccountById(
                              activity.sourceAccountId!,
                            );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, color: Colors.orange),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reserved ${activity.amount.toStringAsFixed(0)} EGP',
                                    style: const TextStyle(color: Colors.white),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    account?.name ?? '',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 32),

            const SizedBox(height: 24),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GoalActionTile(
              icon: Icons.lock,
              label: 'Reserve Money',
              onTap: _reserveMoney,
            ),
            GoalActionTile(
              icon: Icons.savings,
              label: 'Transfer To Saving',
              onTap: _transferToSaving,
            ),
            GoalActionTile(
              icon: Icons.lock_open,
              label: 'Release Goal',
              onTap: _releaseReservation,
            ),
            GoalActionTile(
              icon: Icons.archive,
              label: 'Archive Goal',
              onTap: _archiveGoal,
            ),
          ],
        ),
      ),
    );
  }
}

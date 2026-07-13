// lib/screens/planning/goal_details_screen.dart

import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../../services/goal_projection_service.dart';
import 'widgets/goal_progress_card.dart';
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
import '../../services/transaction_service.dart';
import '../../models/transaction.dart';
import '../../constants/transaction_constants.dart';
import '../../services/goal_details_projection_service.dart';

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
  List<GoalFundingSource> _savedSources = [];

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
    final projection = _fundingProjectionService.getProjection(widget.goal.id);

    final activities = _activityService.getGoalActivities(widget.goal.id);
    final fundingSources = _fundingProjectionService.getFundingSources(
      widget.goal.id,
    );
    final savedSources = projection.savingSources;

    setState(() {
      _saved = projection.totalProgress;

      _progress = widget.goal.targetAmount > 0
          ? (projection.totalProgress / widget.goal.targetAmount).clamp(
              0.0,
              1.0,
            )
          : 0.0;

      _activities = activities;
      _savedSources = savedSources;
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

  Future<void> _executeTransfer({
    required String sourceAccountId,
    required String savingAccountId,
    required double amount,
    required String goalId,
  }) async {
    // Step 1: Reduce Allocation
    await _goalAllocationService.reduceAllocation(
      goalId: goalId,
      accountId: sourceAccountId,
      reductionAmount: amount,
    );

    // Step 2: Create GoalActivity
    GoalActivity activity;
    try {
      activity = GoalActivity.create(
        goalId: goalId,
        type: GoalActivityType.transferToSaving,
        amount: amount,
        sourceAccountId: sourceAccountId,
        destinationAccountId: savingAccountId,
        notes: 'Transfer to saving account',
      );
      await _activityService.addActivity(activity);
    } catch (e) {
      // Rollback Allocation
      await _goalAllocationService.increaseAllocation(
        goalId: goalId,
        accountId: sourceAccountId,
        increaseAmount: amount,
      );
      rethrow;
    }

    // Step 3: Create Transaction
    final transaction = Transaction.create(
      amount: amount,
      type: TransactionType.transfer,
      fromAccountId: sourceAccountId,
      toAccountId: savingAccountId,
      categoryId: "",
      date: DateTime.now(),
      note: 'Transfer to saving from goal funding',
      paymentMethod: 'transfer',
      isExceptional: false,
      currencyCode: 'EGP',
      source: TransactionSource.manual,
    );

    try {
      await TransactionService.instance.addTransaction(transaction);
    } catch (e) {
      // Rollback Allocation + Activity
      await _goalAllocationService.increaseAllocation(
        goalId: goalId,
        accountId: sourceAccountId,
        increaseAmount: amount,
      );
      await _activityService.deleteActivity(activity.id);
      rethrow;
    }

    // Step 4: Reload projection
    await _loadData();
  }

  Future<bool> _transferAllToSaving() async {
    final reservedSources = _fundingSources;
    if (reservedSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reserved funds to transfer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    final savingAccounts = AccountService()
        .getAllActiveAccounts()
        .where((a) => a.type == 'realSaving')
        .toList();

    if (savingAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a saving account first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    final totalReserved = reservedSources.fold<double>(
      0,
      (sum, s) => sum + s.amount,
    );

    final result = await showTransferToSavingDialog(
      context: context,
      availableAmount: totalReserved,
      savingAccounts: savingAccounts,
      allowPartialTransfer: false,
    );

    if (result == null) {
      return false;
    }

    final sourcesCopy = List<GoalFundingSource>.from(reservedSources);
    for (final source in sourcesCopy) {
      await _executeTransfer(
        sourceAccountId: source.accountId,
        savingAccountId: result.savingAccountId,
        amount: source.amount,
        goalId: widget.goal.id,
      );
    }

    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All reserved funds transferred to saving.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return true;
  }

  Future<void> _transferSavingGoalFunding() async {
    final accountService = AccountService();

    final liquidityAccounts = accountService
        .getAllActiveAccounts()
        .where((a) => a.type == 'cash' || a.type == 'bank')
        .toList();

    final savingAccounts = accountService
        .getAllActiveAccounts()
        .where((a) => a.type == 'realSaving')
        .toList();

    if (liquidityAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No liquidity accounts available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (savingAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a saving account first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showTransferToSavingDialog(
      context: context,
      availableAmount: widget.goal.targetAmount,
      savingAccounts: savingAccounts,
      liquidityAccounts: liquidityAccounts,
      requireSourceAccount: true,
      allowPartialTransfer: true,
    );

    if (result == null) {
      return;
    }

    final transaction = Transaction.create(
      amount: result.amount,
      type: TransactionType.transfer,
      fromAccountId: result.sourceAccountId!,
      toAccountId: result.savingAccountId,
      categoryId: '',
      date: DateTime.now(),
      note: 'Saving Goal Contribution',
      paymentMethod: 'transfer',
      isExceptional: false,
      currencyCode: 'EGP',
      source: TransactionSource.manual,
    );

    await TransactionService.instance.addTransaction(transaction);

    await _activityService.addActivity(
      GoalActivity.create(
        goalId: widget.goal.id,
        type: GoalActivityType.transferToSaving,
        amount: result.amount,
        sourceAccountId: result.sourceAccountId,
        destinationAccountId: result.savingAccountId,
        notes: 'Saving Goal Contribution',
      ),
    );

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contribution added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _transferFundingSource(GoalFundingSource source) async {
    final savingAccounts = AccountService()
        .getAllActiveAccounts()
        .where((a) => a.type == 'realSaving')
        .toList();

    if (savingAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a saving account first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showTransferToSavingDialog(
      context: context,
      availableAmount: source.amount,
      savingAccounts: savingAccounts,
      allowPartialTransfer: true,
    );

    if (result != null) {
      await _executeTransfer(
        sourceAccountId: source.accountId,
        savingAccountId: result.savingAccountId,
        amount: result.amount,
        goalId: widget.goal.id,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer to saving completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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

    await _goalAllocationService.releaseFundingSource(
      goalId: widget.goal.id,
      accountId: source.accountId,
    );

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
    } else if (action == 'release') {
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
    } else if (action == 'transfer') {
      final transferSuccess = await _transferAllToSaving();

      if (!transferSuccess) {
        return;
      }

      await _markGoalCompleted();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal completed and funds transferred to saving.'),
        ),
      );
    }
  }

  Future<void> _markGoalCompleted() async {
    final updatedGoal = widget.goal.copyWith(status: GoalStatus.completed);
    await _goalService.update(updatedGoal);
  }

  Future<void> _archiveGoal() async {
    await _markGoalCompleted();

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Goal moved to archive')));
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.goal.status == GoalStatus.completed;
    final isCancelled = widget.goal.status == GoalStatus.cancelled;

    final isAchieved =
        _progress >= 1.0 &&
        _fundingSources.isEmpty &&
        !isCompleted &&
        !isCancelled;
    final hasReleasedCompletion = _activities.any(
      (a) => a.type == 'completed_release',
    );

    final projection = GoalDetailsProjectionService().build(
      goal: widget.goal,
      progress: _progress,
      hasFundingSources: _fundingSources.isNotEmpty,
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

            if (projection.showReserveActions)
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

            if (projection.showSavingActions)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _transferSavingGoalFunding,
                      icon: const Icon(Icons.savings),
                      label: const Text('Transfer To Saving'),
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

            const SizedBox(height: 12),

            if (projection.showCompleteGoalButton && !isAchieved)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _completeGoal,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Goal'),
                ),
              ),

            if (projection.showArchiveButton && !isAchieved)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _archiveGoal,
                  icon: const Icon(Icons.archive),
                  label: const Text('Archive Goal'),
                ),
              ),

            if (isAchieved) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: const Text(
                  '🎉 Goal achieved successfully.\nAll funds have been transferred.',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _archiveGoal,
                  icon: const Icon(Icons.archive),
                  label: const Text('Move To Archive'),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // RESERVED SOURCES
            if (projection.showFundingSources &&
                !hasReleasedCompletion &&
                widget.goal.status != GoalStatus.cancelled) ...[
              if (widget.goal.status != GoalStatus.cancelled) ...[
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
                                  _buildFundingSourceTile(
                                    _fundingSources[i],
                                    isSaving: false,
                                  ),
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
            ],

            // SAVED SOURCES
            if (_savedSources.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saved Sources',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_savedSources.length} source${_savedSources.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _savedSources.length; i++)
                      Column(
                        children: [
                          _buildFundingSourceTile(
                            _savedSources[i],
                            isSaving: true,
                          ),
                          if (i < _savedSources.length - 1)
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

  Widget _buildFundingSourceTile(
    GoalFundingSource source, {
    required bool isSaving,
  }) {
    final color = isSaving ? Colors.purple : Colors.green;
    final label = isSaving ? 'Saved' : 'Reserved';
    final icon = isSaving ? Icons.savings : Icons.account_balance_wallet;

    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
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
                Text(
                  label,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${source.amount.toStringAsFixed(0)} EGP',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (!isSaving)
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

    final icon = _getActivityIcon(activity.type);
    final color = _getActivityColor(activity.type);
    final title = _getActivityTitle(activity.type);

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

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'reserve':
        return Icons.lock;
      case 'release':
        return Icons.lock_open;
      case 'cancel':
        return Icons.cancel;
      case 'completed_reserved':
        return Icons.check_circle;
      case 'completed_release':
        return Icons.check_circle;
      case GoalActivityType.transferToSaving:
        return Icons.swap_horiz;
      default:
        return Icons.history;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'reserve':
        return Colors.orange;
      case 'release':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'completed_reserved':
        return Colors.blue;
      case 'completed_release':
        return Colors.green;
      case GoalActivityType.transferToSaving:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getActivityTitle(String type) {
    switch (type) {
      case 'reserve':
        return 'Reserved';
      case 'release':
        return 'Released';
      case 'cancel':
        return 'Cancelled';
      case 'completed_reserved':
        return 'Completed';
      case 'completed_release':
        return 'Completed & Released';
      case GoalActivityType.transferToSaving:
        return 'Transferred to Saving';
      default:
        return type;
    }
  }
}

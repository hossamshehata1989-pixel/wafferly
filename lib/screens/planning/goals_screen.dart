// lib/screens/planning/goals_screen.dart

import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../../services/goal_service.dart';
import '../../services/goal_funding_projection_service.dart'; // ✅ استبدال import
import '../../services/goal_allocation_service.dart';
import '../../services/account_service.dart';
import '../../models/enums/account_enums.dart';
import '../../models/enums/goal_type.dart';
import 'goal_details_screen.dart';
import '../../models/enums/goal_status.dart';
import 'create_goal_screen.dart';
import 'package:flutter/services.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalService _goalService = GoalService();
  final GoalAllocationService _goalAllocationService = GoalAllocationService();

  // ✅ استبدال GoalProjectionService بـ GoalFundingProjectionService
  final GoalFundingProjectionService _projectionService =
      GoalFundingProjectionService();

  List<Goal> goals = [];
  bool showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    final loadedGoals = _goalService.getAll();
    if (!mounted) return;
    setState(() {
      goals = loadedGoals;
    });
  }

  Widget _buildGoalCard(Goal goal, bool isTablet) {
    // ✅ استخدام getProjection() مباشرة (متزامن)
    final projection = _projectionService.getProjection(goal.id);
    final allocated =
        projection.totalProgress; // totalReserved + totalSaved (saved = 0)

    final progress = goal.status == GoalStatus.completed
        ? 1.0
        : goal.targetAmount <= 0
        ? 0.0
        : (allocated / goal.targetAmount).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(0);
    final remaining = (goal.targetAmount - allocated).clamp(
      0.0,
      double.infinity,
    );
    final isCompleted = goal.status == GoalStatus.completed;
    final isCancelled = goal.status == GoalStatus.cancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
              : [const Color(0xFF1B2A6B), const Color(0xFF0F1115)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : const Color(0xFF243A8F),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailsScreen(goal: goal),
              ),
            );
            if (!mounted) return;
            _loadGoals();
            setState(() {});
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _getProgressColor(progress).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _getGoalIcon(goal.title),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCompleted
                                ? "Completed Goal 🎉"
                                : "${remaining.toStringAsFixed(0)} EGP remaining",
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getProgressColor(progress).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$percent%",
                        style: TextStyle(
                          color: _getProgressColor(progress),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    color: _getProgressColor(progress),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Allocated: ${allocated.toStringAsFixed(0)} EGP",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Target: ${goal.targetAmount.toStringAsFixed(0)} EGP",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String fundingMethod = 'saving';
    GoalType selectedType = GoalType.manual;
    final contributionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Goal",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Goal name",
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A7BFF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              StatefulBuilder(
                builder: (context, setSheetState) {
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedType = GoalType.manual;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedType == GoalType.manual
                                  ? const Color(0xFF3A7BFF)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.touch_app, color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  'Manual Goal',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedType = GoalType.recurring;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedType == GoalType.recurring
                                  ? const Color(0xFF3A7BFF)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.repeat, color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  'Scheduled Goal',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Funding Method',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              StatefulBuilder(
                builder: (context, setFundingState) {
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setFundingState(() {
                              fundingMethod = 'saving';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: fundingMethod == 'saving'
                                  ? const Color(0xFF3A7BFF)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.savings, color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  'Real Saving',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setFundingState(() {
                              fundingMethod = 'reserve';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: fundingMethod == 'reserve'
                                  ? const Color(0xFF3A7BFF)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.lock, color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  'Reserve Money',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Target amount",
                  labelStyle: TextStyle(color: Colors.white54),
                  prefixText: "EGP ",
                  prefixStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A7BFF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final goal = Goal.create(
                    title: titleController.text,
                    targetAmount: double.tryParse(amountController.text) ?? 0,
                    type: selectedType,
                  );
                  await _goalService.add(goal);
                  Navigator.pop(context);
                  _loadGoals();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BFF),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGoalOptions(Goal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.orange,
                ),
                title: const Text(
                  'Goal Actions',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showGoalActions(goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Delete Goal",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteGoal(goal);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAllocationDialog(Goal goal) {
    final accounts = AccountService()
        .getAllActiveAccounts()
        .where((a) => a.group == AccountGroup.liquidity)
        .toList();

    String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a cash or bank account first')),
      );
      return;
    }

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reserve For ${goal.title}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Source Account',
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedAccountId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Amount'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;

              final success = await _goalAllocationService.createAllocation(
                accountId: selectedAccountId!,
                goalId: goal.id,
                amount: amount,
              );

              Navigator.pop(context);
              if (!mounted) return;

              if (success) {
                _loadGoals();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Money reserved successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough available balance')),
                );
              }
            },
            child: const Text('Reserve'),
          ),
        ],
      ),
    );
  }

  void _showGoalActions(Goal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Reserve Money'),
                onTap: () {
                  Navigator.pop(context);
                  _showAllocationDialog(goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.savings),
                title: const Text('Transfer To Saving'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming Soon')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text('Release Reservation'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming Soon')));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text("Delete Goal", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete '${goal.title}'?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _goalService.delete(goal.id);
              Navigator.pop(context);
              _loadGoals();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getGoalIcon(String title) {
    const icons = {
      'car': '🚗',
      'travel': '✈️',
      'house': '🏠',
      'education': '🎓',
      'phone': '📱',
      'laptop': '💻',
      'gift': '🎁',
      'wedding': '💍',
      'baby': '👶',
      'investment': '📈',
    };
    for (final entry in icons.entries) {
      if (title.toLowerCase().contains(entry.key)) return entry.value;
    }
    return '🎯';
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final activeGoals = goals
        .where((g) => g.status == GoalStatus.active)
        .toList();
    final completedGoals = goals
        .where((g) => g.status == GoalStatus.completed)
        .toList();
    final cancelledGoals = goals
        .where((g) => g.status == GoalStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          "Goals",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("🎯", style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    "No goals yet",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap + to create your first goal",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Toggle between Active and Archived
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Active'),
                          selected: !showArchived,
                          onSelected: (_) =>
                              setState(() => showArchived = false),
                          selectedColor: const Color(0xFF3A7BFF),
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(
                            color: !showArchived
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Archived'),
                          selected: showArchived,
                          onSelected: (_) =>
                              setState(() => showArchived = true),
                          selectedColor: const Color(0xFF3A7BFF),
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(
                            color: showArchived ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: showArchived
                      ? (completedGoals.isEmpty && cancelledGoals.isEmpty)
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.archive_outlined,
                                      size: 72,
                                      color: Colors.white24,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No Archived Goals',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Completed and cancelled goals will appear here',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    completedGoals.length +
                                    cancelledGoals.length +
                                    2,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Text(
                                        'Completed Goals',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  } else if (index ==
                                      completedGoals.length + 1) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Text(
                                        'Cancelled Goals',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  } else if (index <= completedGoals.length) {
                                    final goal = completedGoals[index - 1];
                                    return _buildGoalCard(goal, isTablet);
                                  } else {
                                    final goal =
                                        cancelledGoals[index -
                                            completedGoals.length -
                                            2];
                                    return _buildGoalCard(goal, isTablet);
                                  }
                                },
                              )
                      : activeGoals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('🎯', style: TextStyle(fontSize: 64)),
                              SizedBox(height: 16),
                              Text(
                                'No Active Goals',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create a new goal or view archived goals',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: activeGoals.length,
                          itemBuilder: (context, index) =>
                              _buildGoalCard(activeGoals[index], isTablet),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "goalsFab",
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
          );
          _loadGoals();
        },
        icon: const Icon(Icons.flag),
        label: const Text('New Goal'),
      ),
    );
  }
}

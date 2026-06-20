class GoalDetailsProjection {
  final bool showReserveActions;
  final bool showSavingActions;

  final bool showFundingSources;

  final bool showCompleteGoalButton;
  final bool showArchiveButton;

  const GoalDetailsProjection({
    required this.showReserveActions,
    required this.showSavingActions,
    required this.showFundingSources,
    required this.showCompleteGoalButton,
    required this.showArchiveButton,
  });
}

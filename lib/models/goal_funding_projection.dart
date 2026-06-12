import 'goal_funding_source.dart';

class GoalFundingProjection {
  final List<GoalFundingSource> reservedSources;

  final List<GoalFundingSource> savingSources;

  final double totalReserved;

  final double totalSaved;

  final double totalProgress;

  const GoalFundingProjection({
    required this.reservedSources,
    required this.savingSources,
    required this.totalReserved,
    required this.totalSaved,
    required this.totalProgress,
  });
}

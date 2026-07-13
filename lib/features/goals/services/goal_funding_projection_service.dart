import '../models/goal_funding_projection.dart';

class GoalFundingProjectionService {
  Future<GoalFundingProjection> getProjection(String goalId) async {
    return const GoalFundingProjection(
      reservedSources: [],
      savingSources: [],
      totalReserved: 0,
      totalSaved: 0,
      totalProgress: 0,
    );
  }
}

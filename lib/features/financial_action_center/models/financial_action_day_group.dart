import 'financial_action_group.dart';
import 'financial_action_projection_group.dart';

class FinancialActionDayGroup {
  final FinancialActionGroup group;

  final List<FinancialActionProjectionGroup> actions;

  const FinancialActionDayGroup({required this.group, required this.actions});
}

import '../models/financial_action_group.dart';

class FinancialActionGroupMapper {
  const FinancialActionGroupMapper();

  String title(FinancialActionGroup group) {
    switch (group) {
      case FinancialActionGroup.overdue:
        return 'Overdue';

      case FinancialActionGroup.today:
        return 'Today';

      case FinancialActionGroup.tomorrow:
        return 'Tomorrow';

      case FinancialActionGroup.upcoming:
        return 'Upcoming';
    }
  }
}

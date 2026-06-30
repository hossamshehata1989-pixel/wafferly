import 'package:flutter/foundation.dart';

import '../../../models/scheduled_action_execution_context.dart';
import '../../../services/financial_action_engine.dart';
import '../models/financial_action_filter.dart';
import '../../../models/enums/scheduled_action_kind.dart';
import '../services/financial_action_grouping_service.dart';
import '../models/financial_action_day_group.dart';

class FinancialActionCenterController extends ChangeNotifier {
  final FinancialActionEngine engine;

  FinancialActionCenterController({required this.engine});

  final List<ScheduledActionExecutionContext> _actions = [];
  FinancialActionFilter _selectedFilter = FinancialActionFilter.all;

  FinancialActionFilter get selectedFilter => _selectedFilter;
  final FinancialActionGroupingService _groupingService =
      const FinancialActionGroupingService();

  List<FinancialActionDayGroup> get visibleGroups {
    final filtered = _actions.where((item) {
      switch (_selectedFilter) {
        case FinancialActionFilter.all:
          return true;

        case FinancialActionFilter.expenses:
          return item.action.kind == ScheduledActionKind.expense;

        case FinancialActionFilter.income:
          return item.action.kind == ScheduledActionKind.income;

        case FinancialActionFilter.transfers:
          return item.action.kind == ScheduledActionKind.transfer;

        case FinancialActionFilter.goals:
          return item.action.kind == ScheduledActionKind.goalContribution;

        case FinancialActionFilter.investments:
          return item.action.kind == ScheduledActionKind.investment;
      }
    }).toList();

    return _groupingService.group(filtered);
  }

  List<ScheduledActionExecutionContext> get actions =>
      List.unmodifiable(_actions);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Map<FinancialActionFilter, int> get counts {
    return {
      FinancialActionFilter.all: _actions.length,

      FinancialActionFilter.expenses: _actions
          .where((a) => a.action.kind == ScheduledActionKind.expense)
          .length,

      FinancialActionFilter.income: _actions
          .where((a) => a.action.kind == ScheduledActionKind.income)
          .length,

      FinancialActionFilter.transfers: _actions
          .where((a) => a.action.kind == ScheduledActionKind.transfer)
          .length,

      FinancialActionFilter.goals: _actions
          .where((a) => a.action.kind == ScheduledActionKind.goalContribution)
          .length,

      FinancialActionFilter.investments: _actions
          .where((a) => a.action.kind == ScheduledActionKind.investment)
          .length,
    };
  }

  Future<void> loadActions() async {
    _isLoading = true;
    notifyListeners();

    _actions
      ..clear()
      ..addAll(await engine.getActions(today: DateTime.now()));
    debugPrint('Loaded Actions: ${_actions.length}');

    for (final action in _actions) {
      debugPrint(
        '${action.action.title} - ${action.action.dueDate} - ${action.action.kind}',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  void removeAction(ScheduledActionExecutionContext context) {
    _actions.removeWhere((item) => item.action.id == context.action.id);
    notifyListeners();
  }

  void changeFilter(FinancialActionFilter filter) {
    if (_selectedFilter == filter) return;

    _selectedFilter = filter;
    notifyListeners();
  }
}

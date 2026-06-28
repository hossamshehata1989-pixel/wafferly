import 'package:flutter/foundation.dart';

import '../../../models/scheduled_action_execution_context.dart';
import '../../../services/financial_action_engine.dart';

class FinancialActionCenterController extends ChangeNotifier {
  final FinancialActionEngine engine;

  FinancialActionCenterController({required this.engine});

  final List<ScheduledActionExecutionContext> _actions = [];

  List<ScheduledActionExecutionContext> get actions =>
      List.unmodifiable(_actions);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> loadActions() async {
    _isLoading = true;
    notifyListeners();

    _actions
      ..clear()
      ..addAll(await engine.getActions(today: DateTime.now()));

    _isLoading = false;
    notifyListeners();
  }

  void removeAction(ScheduledActionExecutionContext context) {
    _actions.removeWhere((item) => item.action.id == context.action.id);
    notifyListeners();
  }
}

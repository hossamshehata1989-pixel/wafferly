import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../financial_engine/engine/financial_operation_engine.dart';

import '../../services/financial_action_engine.dart';
import '../../services/providers/commitment_action_provider.dart';
import '../../services/schedule_evaluator.dart';
import '../../../services/schedule_occurrence_service.dart';
import '../../services/schedule_rule_service.dart';

import 'controller/financial_action_center_controller.dart';
import 'screens/financial_action_panel.dart';
import 'services/financial_action_executor.dart';

class FinancialActionCenter extends StatefulWidget {
  final VoidCallback onSkip;

  const FinancialActionCenter({
    super.key,
    required this.onSkip,
  });

  @override
  State<FinancialActionCenter> createState() =>
      _FinancialActionCenterState();
}

class _FinancialActionCenterState extends State<FinancialActionCenter> {
  late final FinancialActionCenterController controller;
  late final ScheduleOccurrenceService occurrenceService;

  @override
void initState() {
  super.initState();

  debugPrint('FAC: initState START');

  occurrenceService = ScheduleOccurrenceService(
    ruleService: ScheduleRuleService(),
  );

  debugPrint('FAC: occurrenceService CREATED');

  controller = FinancialActionCenterController(
    engine: FinancialActionEngine(
      providers: [
        CommitmentActionProvider(
          evaluator: const ScheduleEvaluator(),
          occurrenceService: occurrenceService,
        ),
      ],
    ),
  );

  debugPrint('FAC: controller CREATED');
  debugPrint('FAC: calling loadActions');

  controller.loadActions();

  debugPrint('FAC: loadActions CALLED');
}

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final executor = FinancialActionExecutor(
      engine: context.read<FinancialOperationEngine>(),
      occurrenceService: occurrenceService,
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return FinancialActionPanel(
          filterCounts: controller.counts,
          isLoading: controller.isLoading,
          groups: controller.visibleGroups,
          selectedFilter: controller.selectedFilter,
          onFilterChanged: controller.changeFilter,
          onExecute: (action) async {
            final success = await executor.execute(
              context,
              action,
            );

            if (success) {
              controller.removeAction(action);

              if (controller.actions.isEmpty) {
                await Future.delayed(
                  const Duration(milliseconds: 1500),
                );

                if (mounted) {
                  widget.onSkip();
                }
              }
            }
          },
          onSkip: widget.onSkip,
        );
      },
    );
  }
}
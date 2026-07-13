import 'package:flutter/material.dart';

import '../../services/financial_action_engine.dart';
import '../../services/providers/commitment_action_provider.dart';
import '../../services/schedule_evaluator.dart';

import 'controller/financial_action_center_controller.dart';
import 'package:wafferly/features/financial_action_center/screens/financial_action_panel.dart';
import 'services/financial_action_executor.dart';

class FinancialActionCenter extends StatefulWidget {
  final VoidCallback onSkip;

  const FinancialActionCenter({super.key, required this.onSkip});

  @override
  State<FinancialActionCenter> createState() => _FinancialActionCenterState();
}

class _FinancialActionCenterState extends State<FinancialActionCenter> {
  late final FinancialActionCenterController controller;
  late final FinancialActionExecutor executor;

  @override
  void initState() {
    super.initState();

    controller = FinancialActionCenterController(
      engine: FinancialActionEngine(
        providers: [
          CommitmentActionProvider(evaluator: const ScheduleEvaluator()),
        ],
      ),
    );

    executor = const FinancialActionExecutor();
    controller.loadActions();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            final success = await executor.execute(context, action);

            if (success) {
              controller.removeAction(action);

              if (controller.actions.isEmpty) {
                await Future.delayed(const Duration(milliseconds: 1500));

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

import 'package:flutter/material.dart';

import '../../services/financial_action_engine.dart';
import '../../services/providers/commitment_action_provider.dart';
import '../../services/schedule_evaluator.dart';

import 'controller/financial_action_center_controller.dart';
import 'package:wafferly/features/financial_action_center/screens/financial_action_panel.dart';

class FinancialActionCenter extends StatefulWidget {
  final VoidCallback onSkip;

  const FinancialActionCenter({super.key, required this.onSkip});

  @override
  State<FinancialActionCenter> createState() => _FinancialActionCenterState();
}

class _FinancialActionCenterState extends State<FinancialActionCenter> {
  late final FinancialActionCenterController controller;

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
      builder: (_, __) {
        return FinancialActionPanel(
          actions: controller.actions,
          onExecute: (_) {},
          onSkip: widget.onSkip,
        );
      },
    );
  }
}

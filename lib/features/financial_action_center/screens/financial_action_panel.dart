import 'package:flutter/material.dart';

import '../../../models/scheduled_action_execution_context.dart';

import '../widgets/financial_action_card.dart';
import '../mappers/financial_action_display_mapper.dart';
import '../widgets/financial_action_footer.dart';
import '../widgets/financial_action_filters.dart';
import '../widgets/action_day_section.dart';
import '../widgets/financial_action_card_v2.dart';

class FinancialActionPanel extends StatelessWidget {
  final VoidCallback onSkip;

  final List<ScheduledActionExecutionContext> actions;

  final void Function(ScheduledActionExecutionContext context) onExecute;
  final bool isLoading;

  const FinancialActionPanel({
    super.key,
    required this.actions,
    required this.onExecute,
    required this.onSkip,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    const mapper = FinancialActionDisplayMapper();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          children: [
            // ========== HEADER ==========
            _FinancialActionHeader(
              pendingCount: actions.length,
              estimatedDuration: const Duration(seconds: 40),
            ),
            const SizedBox(height: 8), // ✅ تقليل المسافة

            const FinancialActionFilters(),

            const Divider(height: 0.5), // ✅ تقليل ارتفاع الفاصل
            // ========== MAIN CONTENT ==========
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (actions.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 56),
                          SizedBox(height: 16),
                          Text('All caught up!'),
                          SizedBox(height: 8),
                          Text('No financial actions.'),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.zero, // ✅ إزالة padding إضافي
                    children: [
                      ActionDaySection(
                        title: 'Today',
                        count: actions.length,
                        child: Column(
                          children: actions.map((item) {
                            final display = mapper.fromContext(item);

                            return FinancialActionCardV2(
                              display: display,
                              onExecute: () => onExecute(item),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ========== FOOTER ==========
            const Divider(height: 0.5), // ✅ تقليل ارتفاع الفاصل
            FinancialActionFooter(onSkip: onSkip),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// _FinancialActionHeader
// ============================================================

class _FinancialActionHeader extends StatelessWidget {
  final int pendingCount;
  final Duration estimatedDuration;

  const _FinancialActionHeader({
    required this.pendingCount,
    required this.estimatedDuration,
  });

  String _buildSubtitle() {
    final minutes = estimatedDuration.inMinutes;
    final seconds = estimatedDuration.inSeconds % 60;

    if (minutes > 0) {
      return '$pendingCount pending actions · Est. $minutes min ${seconds}s';
    }

    return '$pendingCount pending actions · Est. ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 1, 1, 1), // ✅ تقليل padding
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15), // ✅ تصغير الأيقونة
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF3A7BFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Financial Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 24, // ✅ تصغير الخط قليلاً
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _buildSubtitle(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

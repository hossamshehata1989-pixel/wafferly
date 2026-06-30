import 'package:flutter/material.dart';

import '../../../models/scheduled_action_execution_context.dart';

import '../mappers/financial_action_display_mapper.dart';
import '../widgets/financial_action_footer.dart';
import '../widgets/financial_action_filters.dart';
import '../widgets/action_day_section.dart';
import '../widgets/financial_action_card_v2.dart';
import '../models/financial_action_filter.dart';
import '../models/financial_action_day_group.dart';

class FinancialActionPanel extends StatelessWidget {
  final VoidCallback onSkip;

  final List<FinancialActionDayGroup> groups;

  final void Function(ScheduledActionExecutionContext context) onExecute;
  final bool isLoading;
  final FinancialActionFilter selectedFilter;

  final ValueChanged<FinancialActionFilter> onFilterChanged;

  // ⭐ المضافة
  final Map<FinancialActionFilter, int> filterCounts;

  const FinancialActionPanel({
    super.key,
    required this.groups,
    required this.onExecute,
    required this.onSkip,
    required this.isLoading,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filterCounts, // ✅ إلزامي
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
              pendingCount: groups.fold(
                0,
                (sum, group) => sum + group.actions.length,
              ),
              estimatedDuration: const Duration(seconds: 40),
            ),
            const SizedBox(height: 8),

            // ⭐ تمرير filterCounts إلى الـ Filters
            FinancialActionFilters(
              selectedFilter: selectedFilter,
              onFilterChanged: onFilterChanged,
              counts: filterCounts, // ✅ تم التمرير
            ),

            const Divider(height: 0.5),
            // ========== MAIN CONTENT ==========
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (groups.isEmpty) {
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
                    padding: EdgeInsets.zero,
                    children: groups.map((group) {
                      return ActionDaySection(
                        title: group.group.name.toUpperCase(),
                        count: group.actions.length,
                        child: Column(
                          children: group.actions.map((item) {
                            final display = mapper.fromContext(item);

                            return FinancialActionCardV2(
                              display: display,
                              onExecute: () => onExecute(item),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // ========== FOOTER ==========
            const Divider(height: 0.5),
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
      padding: const EdgeInsets.fromLTRB(1, 1, 1, 1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
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
                    fontSize: 24,
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

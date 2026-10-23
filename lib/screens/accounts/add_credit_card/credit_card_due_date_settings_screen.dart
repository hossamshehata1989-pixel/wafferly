import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_due_date_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../shared/widgets/wafferly_button.dart';

@immutable
class CreditCardDueDateSettings {
  const CreditCardDueDateSettings({
    required this.calculationMethod,
    required this.daysAfterStatement,
    required this.weekendHolidayPolicy,
  });

  final String calculationMethod;
  final int daysAfterStatement;
  final String weekendHolidayPolicy;
}

class CreditCardDueDateSettingsScreen extends StatefulWidget {
  const CreditCardDueDateSettingsScreen({
    super.key,
    required this.initialSettings,
  });

  final CreditCardDueDateSettings initialSettings;

  @override
  State<CreditCardDueDateSettingsScreen> createState() =>
      _CreditCardDueDateSettingsScreenState();
}

class _CreditCardDueDateSettingsScreenState
    extends State<CreditCardDueDateSettingsScreen> {
  late String _calculationMethod;
  late int _daysAfterStatement;
  late String _weekendHolidayPolicy;

  @override
  void initState() {
    super.initState();
    _calculationMethod = widget.initialSettings.calculationMethod;
    _daysAfterStatement = widget.initialSettings.daysAfterStatement;
    _weekendHolidayPolicy = widget.initialSettings.weekendHolidayPolicy;
  }

  void _save() {
    Navigator.of(context).pop(
      CreditCardDueDateSettings(
        calculationMethod: _calculationMethod,
        daysAfterStatement: _daysAfterStatement,
        weekendHolidayPolicy: _weekendHolidayPolicy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;
    final offsetMode =
        _calculationMethod == CreditCardDueDatePolicy.fixedOffsetDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.dueDateAdvancedSettings,
          style: TextStyle(
            fontSize: m.typography.title,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  m.spacing(16),
                  m.spacing(8),
                  m.spacing(16),
                  m.spacing(24),
                ),
                children: [
                  _InfoCard(
                    icon: Icons.info_outline_rounded,
                    child: Text(
                      t.dueDateExplanation,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontSize: m.typography.body,
                      ),
                    ),
                  ),
                  SizedBox(height: m.space.lg),
                  Text(
                    t.howDueDateCalculated,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: m.typography.title,
                    ),
                  ),
                  SizedBox(height: m.space.sm),
                  _ChoiceCard(
                    selected: !offsetMode,
                    icon: Icons.calendar_month_rounded,
                    title: t.fixedDayEachMonth,
                    subtitle: t.fixedDayEachMonthDescription,
                    onTap: () => setState(() => _calculationMethod =
                        CreditCardDueDatePolicy.fixedCalendarDay),
                  ),
                  SizedBox(height: m.space.sm),
                  _ChoiceCard(
                    selected: offsetMode,
                    icon: Icons.event_repeat_rounded,
                    title: t.daysAfterStatementClosing,
                    subtitle: t.daysAfterStatementClosingDescription,
                    onTap: () => setState(() => _calculationMethod =
                        CreditCardDueDatePolicy.fixedOffsetDays),
                  ),
                  if (offsetMode) ...[
                    SizedBox(height: m.space.md),
                    Container(
                      padding: EdgeInsets.all(m.space.md),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(m.radius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.daysAfterStatementClosing,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: m.typography.body,
                            ),
                          ),
                          SizedBox(height: m.space.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _daysAfterStatement,
                            dropdownColor: AppColors.card,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (var day = 1; day <= 90; day++)
                                DropdownMenuItem<int>(
                                  value: day,
                                  child: Text('$day ${t.daysAfterClosingShort}'),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _daysAfterStatement = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: m.space.lg),
                  Text(
                    t.weekendHolidayHandling,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: m.typography.title,
                    ),
                  ),
                  SizedBox(height: m.space.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _weekendHolidayPolicy,
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(m.radius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(m.radius.md),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: CreditCardDueDatePolicy.noAdjustment,
                        child: Text(t.noAdjustment),
                      ),
                      DropdownMenuItem(
                        value: CreditCardDueDatePolicy.nextBusinessDay,
                        child: Text(t.nextBusinessDay),
                      ),
                      DropdownMenuItem(
                        value: CreditCardDueDatePolicy.previousBusinessDay,
                        child: Text(t.previousBusinessDay),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _weekendHolidayPolicy = value);
                      }
                    },
                  ),
                  SizedBox(height: m.space.sm),
                  _InfoCard(
                    icon: Icons.account_balance_outlined,
                    child: Text(
                      t.bankHolidayNote,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontSize: m.typography.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                m.spacing(12),
                m.spacing(8),
                m.spacing(12),
                m.spacing(8),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .32),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: .08)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: WafferlyButton(
                  title: t.saveSettings,
                  onPressed: _save,
                  backgroundColor: const Color(0xFFFF1684),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    const selectedColor = Color(0xFFFF1684);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(m.radius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(m.radius.lg),
        child: Container(
          padding: EdgeInsets.all(m.space.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(m.radius.lg),
            border: Border.all(
              color: selected ? selectedColor : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? selectedColor : AppColors.textSecondary,
              ),
              SizedBox(width: m.space.sm),
              Icon(icon, color: selected ? selectedColor : AppColors.accent),
              SizedBox(width: m.space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: m.typography.body,
                      ),
                    ),
                    SizedBox(height: m.space.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: m.typography.caption,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Container(
      padding: EdgeInsets.all(m.space.md),
      decoration: BoxDecoration(
        color: const Color(0xFF21152D),
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: const Color(0xFF67244F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF1684)),
          SizedBox(width: m.space.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

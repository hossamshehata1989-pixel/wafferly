import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_account_application_service.dart';
import '../../../application/credit_card/credit_card_due_date_policy.dart';
import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/account.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../../../shared/widgets/wafferly_dropdown.dart';
import '../../../shared/widgets/wafferly_form_section.dart';
import '../../../shared/widgets/wafferly_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/input/wafferly_input_decoration.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../widgets/shared/wafferly_financial_card.dart';
import 'credit_card_bank_account_selection_screen.dart';
import 'credit_card_due_date_settings_screen.dart';

class AddCreditCardScreen extends StatefulWidget {
  const AddCreditCardScreen({super.key, required this.bankAccount});

  final Account bankAccount;

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  final _applicationService = CreditCardAccountApplicationService();
  late Account _linkedBankAccount;

  String _currency = 'EGP';
  int? _statementClosingDay;
  int? _paymentDueDay;
  int _daysAfterStatement = 25;
  String _dueDateCalculationMethod = CreditCardDueDatePolicy.fixedCalendarDay;
  String _weekendHolidayPolicy = CreditCardDueDatePolicy.noAdjustment;
  final Set<int> _paymentReminderDays = <int>{3};
  String _cardVisual = 'credit_midnight';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _linkedBankAccount = widget.bankAccount;
    _currency = widget.bankAccount.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _changeBankAccount() async {
    final selected = await Navigator.of(context).push<Account>(
      MaterialPageRoute<Account>(
        builder: (_) => CreditCardBankAccountSelectionScreen(
          initialSelectedAccountId: _linkedBankAccount.id,
        ),
      ),
    );
    if (selected == null || !mounted) return;

    final changesCurrency = selected.currency != _currency;
    final hasEnteredAmounts = _limitController.text.trim().isNotEmpty;
    if (changesCurrency && hasEnteredAmounts) {
      final t = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(t.bankAccountCurrencyChangeTitle),
          content: Text(t.bankAccountCurrencyChangeMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.continueLabel),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _limitController.clear();
    }

    setState(() {
      _linkedBankAccount = selected;
      // The preferred payment account and card currency must stay compatible
      // until cross-currency payment is supported through the FX boundary.
      _currency = selected.currency;
    });
  }

  Future<void> _openDueDateSettings() async {
    final result = await Navigator.of(context).push<CreditCardDueDateSettings>(
      MaterialPageRoute<CreditCardDueDateSettings>(
        builder: (_) => CreditCardDueDateSettingsScreen(
          initialSettings: CreditCardDueDateSettings(
            calculationMethod: _dueDateCalculationMethod,
            daysAfterStatement: _daysAfterStatement,
            weekendHolidayPolicy: _weekendHolidayPolicy,
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _dueDateCalculationMethod = result.calculationMethod;
      _daysAfterStatement = result.daysAfterStatement;
      _weekendHolidayPolicy = result.weekendHolidayPolicy;
    });
  }

  Widget _buildLinkedBankAccountCard(
    ResponsiveMetrics m,
    AppLocalizations t,
  ) {
    final provider = _linkedBankAccount.provider?.trim();
    final subtitleParts = <String>[];
    if (provider != null && provider.isNotEmpty) subtitleParts.add(provider);

    return Container(
      padding: EdgeInsets.all(m.space.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: .28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: m.size(42),
            height: m.size(42),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(m.radius.md),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: AppColors.accent,
              size: m.icon.medium,
            ),
          ),
          SizedBox(width: m.space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.linkedBankAccountLabel,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: m.typography.caption,
                  ),
                ),
                SizedBox(height: m.space.xs),
                Text(
                  _linkedBankAccount.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: m.typography.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  SizedBox(height: m.space.xs),
                  Text(
                    subtitleParts.join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: m.typography.caption,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: m.space.xs),
          TextButton(
            onPressed: _changeBankAccount,
            child: Text(t.changeBankAccount),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    // The application service revalidates that the selected bank account is
    // still active and currency-compatible at the persistence boundary.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final t = AppLocalizations.of(context)!;

    try {
      final account = await _applicationService.create(
        name: _nameController.text.trim(),
        bank: _linkedBankAccount.provider?.trim() ?? '',
        currency: _currency,
        creditLimitValue: _limitController.text,
        linkedBankAccountId: _linkedBankAccount.id,
        cardVisual: _cardVisual,
        statementDay: _statementClosingDay,
        paymentDueDay: _dueDateCalculationMethod ==
                CreditCardDueDatePolicy.fixedCalendarDay
            ? _paymentDueDay
            : null,
        dueDateCalculationMethod: _dueDateCalculationMethod,
        dueDaysAfterStatement: _dueDateCalculationMethod ==
                CreditCardDueDatePolicy.fixedOffsetDays
            ? _daysAfterStatement
            : null,
        weekendHolidayPolicy: _weekendHolidayPolicy,
        paymentReminderDays: _paymentReminderDays.toList()..sort(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${account.name} ${t.createdSuccessfully}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.couldNotCreateCreditCard}: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          t.addCreditCard,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: m.typography.title,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  m.spacing(16),
                  m.space.xs,
                  m.spacing(16),
                  m.spacing(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLinkedBankAccountCard(m, t),
                    SizedBox(height: m.space.md),
                    WafferlyFormSection(
                      title: t.basicInformation,
                      children: [
                        WafferlyTextField(
                          spacingAfter: m.isCompactHeight ? 12 : 14,
                          controller: _nameController,
                          label: t.cardName,
                          hint: t.cardNameHint,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? t.enterCardName
                                  : null,
                        ),
                        Container(
                          padding: EdgeInsets.all(m.spacing(6)),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(m.radius.lg),
                            border: Border.all(color: Colors.white.withValues(alpha: .06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Card Visual',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: m.typography.body,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: m.spacing(2)),
                              Text(
                                'Choose a Wafferly design to distinguish this card.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: m.typography.caption,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(height: m.spacing(4)),
                              WafferlyCardVisualPicker(
                                kind: WafferlyCardKind.credit,
                                value: _cardVisual,
                                onChanged: (value) => setState(
                                  () => _cardVisual = value,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: m.spacing(10)),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < m.size(390);
                            final limitField = WafferlyTextField(
                              spacingAfter: 0,
                              controller: _limitController,
                              label: t.creditLimit,
                              hint: '30,000',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                try {
                                  final amount = Money.parse(value?.trim() ?? '');
                                  if (amount <= Money.zero) {
                                    return t.enterValidLimit;
                                  }
                                  return null;
                                } catch (_) {
                                  return t.enterValidLimit;
                                }
                              },
                            );
                            final currencyField = Tooltip(
                              message: t.bankAccountCurrencyLocked,
                              child: InputDecorator(
                                decoration: WafferlyInputDecoration.build(
                                  context,
                                  label: t.currency,
                                ).copyWith(
                                  suffixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.textSecondary,
                                    size: m.icon.small,
                                  ),
                                ),
                                child: Text(
                                  _currency,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: m.typography.body,
                                  ),
                                ),
                              ),
                            );

                            if (compact) {
                              return Column(
                                children: [
                                  limitField,
                                  SizedBox(height: m.isCompactHeight ? m.spacing(10) : m.spacing(12)),
                                  currencyField,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: limitField),
                                SizedBox(width: m.space.sm),
                                SizedBox(width: m.size(96), child: currencyField),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    WafferlyFormSection(
                      title: t.billingCycleAndPayment,
                      children: [
                        SizedBox(height: m.space.md),
                        LayoutBuilder(
                          builder: (context, _) {
                            final offsetMode = _dueDateCalculationMethod ==
                                CreditCardDueDatePolicy.fixedOffsetDays;
                            final statementDayField = _DayOfMonthSelector(
                              label: t.statementClosingDay,
                              value: _statementClosingDay,
                              hint: t.selectDayOfMonth,
                              validator: (value) => value == null
                                  ? t.selectDayOfMonth
                                  : null,
                              onChanged: (value) => setState(
                                () => _statementClosingDay = value,
                              ),
                            );
                            final Widget dueDateField = offsetMode
                                ? InputDecorator(
                                    decoration: WafferlyInputDecoration.build(
                                      context,
                                      label: t.dueDate,
                                    ),
                                    child: Text(
                                      '$_daysAfterStatement ${t.daysAfterClosingShort}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: m.typography.body,
                                      ),
                                    ),
                                  )
                                : _DayOfMonthSelector(
                                    label: t.dueDate,
                                    value: _paymentDueDay,
                                    hint: t.selectDayOfMonth,
                                    validator: (value) => value == null
                                        ? t.selectDayOfMonth
                                        : null,
                                    onChanged: (value) => setState(
                                      () => _paymentDueDay = value,
                                    ),
                                  );
                            final dueDateRow = Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: dueDateField),
                                SizedBox(width: m.space.xs),
                                Padding(
                                  padding: EdgeInsets.only(top: m.spacing(2)),
                                  child: Material(
                                    color: const Color(0xFF25152F),
                                    borderRadius: BorderRadius.circular(m.radius.md),
                                    child: InkWell(
                                      onTap: _openDueDateSettings,
                                      borderRadius: BorderRadius.circular(m.radius.md),
                                      child: Container(
                                        width: m.size(48),
                                        height: m.size(54),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(m.radius.md),
                                          border: Border.all(color: const Color(0xFFFF1684)),
                                        ),
                                        child: const Icon(
                                          Icons.settings_outlined,
                                          color: Color(0xFFFF1684),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );

                            return Column(
                              children: [
                                statementDayField,
                                SizedBox(height: m.space.sm),
                                dueDateRow,
                                SizedBox(height: m.space.xs),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    t.dueDateExplanation,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: m.typography.caption,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: m.space.lg),
                        Text(
                          t.paymentReminders,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: m.typography.body,
                          ),
                        ),
                        SizedBox(height: m.space.xs),
                        Text(
                          t.paymentRemindersHelper,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: m.typography.caption,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: m.space.sm),
                        _ReminderDaysSelector(
                          selectedDays: _paymentReminderDays,
                          onToggle: (day) {
                            setState(() {
                              if (!_paymentReminderDays.add(day)) {
                                _paymentReminderDays.remove(day);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                m.spacing(12),
                m.spacing(6),
                m.spacing(12),
                m.spacing(6),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.only(bottom: m.spacing(2)),
                child: WafferlyButton(
                  onPressed: _save,
                  title: t.createCreditCard,
                  loading: _saving,
                  backgroundColor: const Color(0xFF35E0B5),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DayOfMonthSelector extends StatelessWidget {
  const _DayOfMonthSelector({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hint,
    required this.validator,
    this.days = 31,
    this.itemLabel,
  });

  final String label;
  final int? value;
  final String hint;
  final ValueChanged<int?> onChanged;
  final FormFieldValidator<int> validator;
  final int days;
  final String Function(int day)? itemLabel;

  @override
  Widget build(BuildContext context) {
    return WafferlyDropdown<int>(
      label: label,
      value: value,
      items: [
        for (var day = 1; day <= days; day++)
          DropdownMenuItem<int>(
            value: day,
            child: Text(itemLabel?.call(day) ?? '$day'),
          ),
      ],
      onChanged: onChanged,
      hint: hint,
      validator: validator,
    );
  }
}

class _ReminderDaysSelector extends StatelessWidget {
  const _ReminderDaysSelector({
    required this.selectedDays,
    required this.onToggle,
  });

  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;

  static const _days = <int>[1, 3, 5, 7, 10, 14];

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Wrap(
      spacing: m.space.xs,
      runSpacing: m.space.xs,
      children: [
        for (final day in _days)
          ChoiceChip(
            label: Text('$day'),
            selected: selectedDays.contains(day),
            onSelected: (_) => onToggle(day),
            selectedColor: const Color(0xFFFF1684),
            backgroundColor: AppColors.card,
            labelStyle: TextStyle(
              color: selectedDays.contains(day)
                  ? Colors.white
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: selectedDays.contains(day)
                  ? const Color(0xFFFF1684)
                  : AppColors.border,
            ),
          ),
      ],
    );
  }
}


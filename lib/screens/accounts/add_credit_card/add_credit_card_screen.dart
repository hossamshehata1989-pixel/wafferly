import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_account_application_service.dart';
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
  final _annualFeeController = TextEditingController();
  final _last4Controller = TextEditingController();

  final _applicationService = CreditCardAccountApplicationService();
  late Account _linkedBankAccount;

  String _currency = 'EGP';
  int? _statementStartDay;
  int? _paymentDueDay;
  final Set<int> _graceDays = <int>{};
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
    _annualFeeController.dispose();
    _last4Controller.dispose();
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
    final hasEnteredAmounts = _limitController.text.trim().isNotEmpty ||
        _annualFeeController.text.trim().isNotEmpty;
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
      _annualFeeController.clear();
    }

    setState(() {
      _linkedBankAccount = selected;
      // The preferred payment account and card currency must stay compatible
      // until cross-currency payment is supported through the FX boundary.
      _currency = selected.currency;
    });
  }

  Widget _buildLinkedBankAccountCard(
    ResponsiveMetrics m,
    AppLocalizations t,
  ) {
    final provider = _linkedBankAccount.provider?.trim();
    final number = _linkedBankAccount.accountNumber?.trim();
    final lastDigits = number == null || number.isEmpty
        ? null
        : (number.length <= 4 ? number : number.substring(number.length - 4));
    final subtitleParts = <String>[];
    if (provider != null && provider.isNotEmpty) subtitleParts.add(provider);
    if (lastDigits != null && lastDigits.isNotEmpty) {
      subtitleParts.add('•••• $lastDigits');
    }

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
        last4Digits: _last4Controller.text.trim().isEmpty ? null : _last4Controller.text.trim(),
        cardVisual: _cardVisual,
        annualFeeValue: _annualFeeController.text.trim().isEmpty
            ? null
            : _annualFeeController.text.trim(),
        statementStartDay: _statementStartDay,
        paymentDueDay: _paymentDueDay,
        graceDays: _graceDays.toList()..sort(),
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
                        WafferlyTextField(
                          spacingAfter: m.isCompactHeight ? 12 : 14,
                          controller: _last4Controller,
                          label: t.last4Optional,
                          hint: '4582',
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            return RegExp(r'^\d{4}$').hasMatch(text)
                                ? null
                                : t.enterExactlyFourDigits;
                          },
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
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < m.size(390);
                            final cycleStart = _DayOfMonthSelector(
                              label: t.statementStartDay,
                              value: _statementStartDay,
                              hint: t.selectDayOfMonth,
                              onChanged: (value) =>
                                  setState(() => _statementStartDay = value),
                            );
                            final paymentDue = _DayOfMonthSelector(
                              label: t.paymentDueDay,
                              value: _paymentDueDay,
                              hint: t.selectDayOfMonth,
                              onChanged: (value) =>
                                  setState(() => _paymentDueDay = value),
                            );

                            if (compact) {
                              return Column(
                                children: [
                                  cycleStart,
                                  SizedBox(height: m.space.sm),
                                  paymentDue,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cycleStart),
                                SizedBox(width: m.space.sm),
                                Expanded(child: paymentDue),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: m.space.md),
                        Text(
                          t.graceDays,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: m.typography.body,
                          ),
                        ),
                        SizedBox(height: m.space.xs),
                        Text(
                          t.graceDaysHelper,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: m.typography.caption,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: m.space.sm),
                        _GraceDaysCalendar(
                          selectedDays: _graceDays,
                          onToggle: (day) {
                            setState(() {
                              if (!_graceDays.add(day)) {
                                _graceDays.remove(day);
                              }
                            });
                          },
                        ),
                        if (_graceDays.isNotEmpty) ...[
                          SizedBox(height: m.space.xs),
                          Text(
                            '${t.selectedDays}: ${_graceDays.toList()..sort()}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: m.typography.caption,
                            ),
                          ),
                        ],
                      ],
                    ),
                    WafferlyFormSection(
                      title: t.feesOptional,
                      children: [
                        WafferlyTextField(
                          spacingAfter: m.isCompactHeight ? 10 : 12,
                          controller: _annualFeeController,
                          label: t.annualFeeOptional,
                          hint: t.annualFeeHint,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            try {
                              final amount = Money.parse(text);
                              if (amount < Money.zero) {
                                return t.enterValidAnnualFee;
                              }
                              return null;
                            } catch (_) {
                              return t.enterValidAnnualFee;
                            }
                          },
                        ),
                        SizedBox(height: m.space.xs),
                        Text(
                          t.annualFeeHelper,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: m.typography.caption,
                            height: 1.3,
                          ),
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
  });

  final String label;
  final int? value;
  final String hint;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return WafferlyDropdown<int>(
      label: label,
      value: value,
      items: [
        for (var day = 1; day <= 31; day++)
          DropdownMenuItem<int>(
            value: day,
            child: Text('$day'),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _GraceDaysCalendar extends StatelessWidget {
  const _GraceDaysCalendar({
    required this.selectedDays,
    required this.onToggle,
  });

  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    return Container(
      padding: EdgeInsets.all(m.space.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(m.radius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 31,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: m.space.xs,
          mainAxisSpacing: m.space.xs,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final day = index + 1;
          final selected = selectedDays.contains(day);
          return InkWell(
            onTap: () => onToggle(day),
            borderRadius: BorderRadius.circular(m.radius.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF35E0B5)
                    : Colors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(m.radius.sm),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF35E0B5)
                      : Colors.white.withValues(alpha: .06),
                ),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: m.typography.caption,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

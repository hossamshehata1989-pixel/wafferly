import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_account_application_service.dart';
import '../../../core/money/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../../../shared/widgets/wafferly_dropdown.dart';
import '../../../shared/widgets/wafferly_form_section.dart';
import '../../../shared/widgets/wafferly_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../widgets/shared/wafferly_financial_card.dart';

class AddCreditCardScreen extends StatefulWidget {
  const AddCreditCardScreen({super.key});

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

  String _currency = 'EGP';
  String? _bank;
  String _cardVisual = 'credit_midnight';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _annualFeeController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  Future<void> _selectBank() async {
    final t = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<_BankOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankPickerSheet(
        title: t.selectBankIssuer,
        searchHint: t.searchBank,
        popularLabel: t.popularBanks,
        egyptLabel: t.egypt,
        arabLabel: t.arabCountries,
        globalLabel: t.global,
        customLabel: t.bankNotListed,
        onCustomBank: () async {
          Navigator.of(context).pop();
          final custom = await _showCustomBankDialog();
          if (custom != null && mounted) {
            setState(() => _bank = custom);
          }
        },
      ),
    );

    if (selected != null && mounted) {
      setState(() => _bank = selected.name);
    }
  }

  Future<String?> _showCustomBankDialog() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t.addCustomBank),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: t.bankName,
            hintText: t.bankNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.of(context).pop(value);
            },
            child: Text(t.add),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final t = AppLocalizations.of(context)!;

    try {
      final account = await _applicationService.create(
        name: _nameController.text.trim(),
        bank: _bank ?? '',
        currency: _currency,
        creditLimitValue: _limitController.text,
        last4Digits: _last4Controller.text.trim().isEmpty ? null : _last4Controller.text.trim(),
        cardVisual: _cardVisual,
        annualFeeValue: _annualFeeController.text.trim().isEmpty
            ? null
            : _annualFeeController.text.trim(),
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
                    WafferlyFormSection(
                      title: t.basicInformation,
                      children: [
                        WafferlyTextField(
                          controller: _nameController,
                          label: t.cardName,
                          hint: t.cardNameHint,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? t.enterCardName
                                  : null,
                        ),
                        SizedBox(height: m.space.sm),
                        _BankSelectorField(
                          label: t.bankIssuerOptional,
                          value: _bank,
                          hint: t.selectBankIssuer,
                          onTap: _selectBank,
                          onClear: () => setState(() => _bank = null),
                        ),
                        SizedBox(height: m.space.sm),
                        WafferlyTextField(
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
                        SizedBox(height: m.space.sm),
                        Container(
                          padding: EdgeInsets.all(m.spacing(12)),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(m.radius.lg),
                            border: Border.all(color: Colors.white.withValues(alpha: .06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Card Visual', style: TextStyle(fontWeight: FontWeight.w800)),
                              SizedBox(height: m.space.xs),
                              const Text('Choose a Wafferly design to distinguish this card.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              SizedBox(height: m.space.sm),
                              WafferlyCardVisualPicker(
                                kind: WafferlyCardKind.credit,
                                value: _cardVisual,
                                onChanged: (value) => setState(() => _cardVisual = value),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: m.space.sm),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < m.size(390);
                            final limitField = WafferlyTextField(
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
                            final currencyField = WafferlyDropdown<String>(
                              label: t.currency,
                              value: _currency,
                              items: const [
                                DropdownMenuItem(value: 'EGP', child: Text('EGP')),
                                DropdownMenuItem(value: 'USD', child: Text('USD')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _currency = value);
                                }
                              },
                            );

                            if (compact) {
                              return Column(
                                children: [
                                  limitField,
                                  SizedBox(height: m.space.sm),
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
                      title: t.feesOptional,
                      children: [
                        WafferlyTextField(
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

class _BankSelectorField extends StatelessWidget {
  const _BankSelectorField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final hasValue = value != null && value!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(m.radius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: m.typography.body,
          ),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(m.radius.md),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: m.space.md,
            vertical: m.input.verticalPadding,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_rounded,
              color: hasValue ? const Color(0xFF35E0B5) : AppColors.textSecondary,
              size: m.icon.small,
            ),
            SizedBox(width: m.space.sm),
            Expanded(
              child: Text(
                hasValue ? value! : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasValue ? AppColors.textPrimary : AppColors.textHint,
                  fontSize: m.typography.body,
                ),
              ),
            ),
            if (hasValue)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textSecondary,
              ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: m.icon.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _BankOption {
  const _BankOption({
    required this.name,
    required this.subtitle,
    required this.group,
  });

  final String name;
  final String subtitle;
  final _BankGroup group;
}

enum _BankGroup { egypt, arab, global }

class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet({
    required this.title,
    required this.searchHint,
    required this.popularLabel,
    required this.egyptLabel,
    required this.arabLabel,
    required this.globalLabel,
    required this.customLabel,
    required this.onCustomBank,
  });

  final String title;
  final String searchHint;
  final String popularLabel;
  final String egyptLabel;
  final String arabLabel;
  final String globalLabel;
  final String customLabel;
  final VoidCallback onCustomBank;

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchController = TextEditingController();
  _BankGroup? _filter;

  static const _banks = <_BankOption>[
    _BankOption(
      name: 'CIB',
      subtitle: 'Commercial International Bank • Egypt',
      group: _BankGroup.egypt,
    ),
    _BankOption(
      name: 'Banque Misr',
      subtitle: 'Banque Misr • Egypt',
      group: _BankGroup.egypt,
    ),
    _BankOption(
      name: 'National Bank of Egypt',
      subtitle: 'NBE • Egypt',
      group: _BankGroup.egypt,
    ),
    _BankOption(
      name: 'QNB Egypt',
      subtitle: 'QNB • Egypt',
      group: _BankGroup.egypt,
    ),
    _BankOption(
      name: 'Banque du Caire',
      subtitle: 'Bank of Cairo • Egypt',
      group: _BankGroup.egypt,
    ),
    _BankOption(
      name: 'Emirates NBD',
      subtitle: 'United Arab Emirates',
      group: _BankGroup.arab,
    ),
    _BankOption(
      name: 'First Abu Dhabi Bank',
      subtitle: 'United Arab Emirates',
      group: _BankGroup.arab,
    ),
    _BankOption(
      name: 'Al Rajhi Bank',
      subtitle: 'Saudi Arabia',
      group: _BankGroup.arab,
    ),
    _BankOption(
      name: 'Saudi National Bank',
      subtitle: 'Saudi Arabia',
      group: _BankGroup.arab,
    ),
    _BankOption(
      name: 'QNB Group',
      subtitle: 'Qatar • International',
      group: _BankGroup.arab,
    ),
    _BankOption(
      name: 'HSBC',
      subtitle: 'International',
      group: _BankGroup.global,
    ),
    _BankOption(
      name: 'Citibank',
      subtitle: 'International',
      group: _BankGroup.global,
    ),
    _BankOption(
      name: 'Standard Chartered',
      subtitle: 'International',
      group: _BankGroup.global,
    ),
    _BankOption(
      name: 'Deutsche Bank',
      subtitle: 'International',
      group: _BankGroup.global,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _banks.where((bank) {
      final matchesFilter = _filter == null || bank.group == _filter;
      final matchesQuery = query.isEmpty ||
          bank.name.toLowerCase().contains(query) ||
          bank.subtitle.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.82,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(m.radius.xl),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: m.space.xs),
            Container(
              width: m.size(38),
              height: m.size(4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                m.spacing(16),
                m.space.sm,
                m.spacing(8),
                m.space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: m.typography.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: m.spacing(16)),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(m.radius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: m.space.sm),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: m.spacing(16)),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: widget.popularLabel,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  _FilterChip(
                    label: widget.egyptLabel,
                    selected: _filter == _BankGroup.egypt,
                    onTap: () => setState(() => _filter = _BankGroup.egypt),
                  ),
                  _FilterChip(
                    label: widget.arabLabel,
                    selected: _filter == _BankGroup.arab,
                    onTap: () => setState(() => _filter = _BankGroup.arab),
                  ),
                  _FilterChip(
                    label: widget.globalLabel,
                    selected: _filter == _BankGroup.global,
                    onTap: () => setState(() => _filter = _BankGroup.global),
                  ),
                ],
              ),
            ),
            SizedBox(height: m.space.sm),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  m.spacing(16),
                  0,
                  m.spacing(16),
                  m.spacing(12),
                ),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  if (index == filtered.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: m.space.sm),
                      child: OutlinedButton.icon(
                        onPressed: widget.onCustomBank,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(widget.customLabel),
                      ),
                    );
                  }

                  final bank = filtered[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: m.space.xs,
                      vertical: m.space.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.card,
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.textSecondary,
                        size: m.icon.small,
                      ),
                    ),
                    title: Text(
                      bank.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(bank.subtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(bank),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

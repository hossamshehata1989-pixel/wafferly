import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../controllers/transaction_entry_controller.dart';
import '../../../credit_card/domain/credit_card_profile.dart';
import '../../../credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import '../../../core/planning/bootstrap/planning_engine_bootstrap.dart';
import '../../../core/planning/services/available_balance_projection_service.dart';
import '../../../models/account.dart';
import '../../../models/enums/account_enums.dart';
import '../../../services/balance_service.dart';
import '../../../theme/app_colors.dart';
import '../../bottom_sheet/sheet_footer.dart';
import '../../bottom_sheet/sheet_header.dart';
import '../../bottom_sheet/wafferly_bottom_sheet.dart';
import '../../../screens/accounts/add_account/add_account_screen.dart';
import '../../../models/enums/section_type.dart';
import '../../../features/transactions/models/expense_payment_mode.dart';

Future<void> showPaymentMethodSheet({
  required BuildContext context,
  required TransactionEntryController controller,
}) async {
  await WafferlyBottomSheet.show(
    context: context,
    scrollable: true,
    bodyPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: _PaymentMethodSheet(controller: controller),
  );
}

class _PaymentMethodSheet extends StatefulWidget {
  const _PaymentMethodSheet({required this.controller});

  final TransactionEntryController controller;

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  late Future<_PaymentSources> _future;
  ExpensePaymentMode _mode = ExpensePaymentMode.fullPayment;
  String? _financingSourceId;
  int _installmentMonths = 6;
  double _downPayment = 0;

  TransactionEntryController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _mode = controller.expensePaymentMode;
    _future = _loadSources();
    _downPayment = _parseAmount();
  }

  double _parseAmount() => double.tryParse(controller.amount) ?? 0;

  Future<_PaymentSources> _loadSources() async {
    final accounts = controller.activeAccounts;
    final liquidity = accounts
        .where((a) => a.group == AccountGroup.liquidity)
        .toList();
    final savings = accounts
        .where((a) => a.group == AccountGroup.savings)
        .toList();
    final prepaid = accounts
        .where((a) => a.type == 'prepaid')
        .toList();
    final creditCardAccounts = accounts
        .where(
          (a) =>
              a.group == AccountGroup.liabilities &&
              a.type == 'creditCard',
        )
        .toList();
    final financingProviders = accounts
        .where(
          (a) =>
              a.group == AccountGroup.liabilities &&
              a.type == 'installment',
        )
        .toList();

    final allocationRepository =
        PlanningEngineBootstrap.createProductionAllocationRepository();
    final projectionService = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: projectionService,
    );

    final balances = <String, double>{};
    for (final account in [...liquidity, ...savings, ...prepaid]) {
      balances[account.id] =
          await balanceService.getAvailableBalanceFromPlanning(account.id);
    }

    final profileRepository = HiveCreditCardProfileRepository(
      Hive.box<CreditCardProfile>('credit_card_profiles'),
    );
    final creditCards = <_CreditCardSource>[];
    for (final account in creditCardAccounts) {
      final profile = await profileRepository.findByAccountId(account.id);
      if (profile == null) continue;

      final rawBalance = balanceService.getBalance(account.id);
      final outstanding = rawBalance < 0 ? -rawBalance : 0.0;
      final available = (profile.creditLimit.toDouble() - outstanding)
          .clamp(0.0, double.infinity)
          .toDouble();

      creditCards.add(
        _CreditCardSource(
          account: account,
          profile: profile,
          outstanding: outstanding,
          available: available,
        ),
      );
    }

    return _PaymentSources(
      liquidity: liquidity,
      savings: savings,
      prepaid: prepaid,
      creditCards: creditCards,
      financingProviders: financingProviders,
      balances: balances,
    );
  }



  void _selectFullAccount(Account account) {
    controller.setExpensePaymentMode(ExpensePaymentMode.fullPayment);
    controller.selectAccount(account.id, account.name);
    Navigator.of(context).pop();
  }

  void _selectCreditCard(_CreditCardSource card) {
    controller.setExpensePaymentMode(ExpensePaymentMode.fullPayment);
    controller.selectAccount(card.account.id, card.account.name);
    Navigator.of(context).pop();
  }

  void _showInstallmentNotPersisted() {
    final amount = _parseAmount();
    if (_financingSourceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a financing option first.')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the purchase amount first.')),
      );
      return;
    }

    final financed = _mode == ExpensePaymentMode.downPaymentInstallment
        ? (amount - _downPayment).clamp(0.0, amount).toDouble()
        : amount;
    final monthly = financed / _installmentMonths;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Installment plan selected: $_installmentMonths months • '
          'EGP ${monthly.toStringAsFixed(0)}/month. '
          'Financing save flow remains behind the Financing Engine boundary.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PaymentSources>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Unable to load payment sources: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final sources = snapshot.data!;
        final canInstallment =
            sources.creditCards.isNotEmpty ||
            sources.financingProviders.isNotEmpty;

        if (!canInstallment && _mode != ExpensePaymentMode.fullPayment) {
          _mode = ExpensePaymentMode.fullPayment;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: 'Payment Method',
              subtitle: 'How do you want to pay for this purchase?',
              icon: Icons.account_balance_wallet_outlined,
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _ModeTabs(
              selected: _mode,
              showInstallment: canInstallment,
              onChanged: (mode) => setState(() {
                _mode = mode;
              }),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_mode) {
                ExpensePaymentMode.fullPayment =>
                  _buildFullPayment(sources),
                ExpensePaymentMode.installment =>
                  _buildInstallment(sources, downPayment: false),
                ExpensePaymentMode.downPaymentInstallment =>
                  _buildInstallment(sources, downPayment: true),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFullPayment(_PaymentSources sources) {
    return Column(
      key: const ValueKey('full-payment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          icon: Icons.payments_outlined,
          title: 'Money You Have',
          subtitle: 'Pay from your existing money',
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        ...sources.liquidity.map(
          (account) => _SourceCard(
            account: account,
            amountLabel:
                '${account.currency} ${(sources.balances[account.id] ?? 0).toStringAsFixed(0)}',
            secondaryLabel:
                'Available ${(sources.balances[account.id] ?? 0).toStringAsFixed(0)}',
            selected: controller.selectedAccountId == account.id,
            accent: _accentForAccount(account),
            onTap: () => _selectFullAccount(account),
          ),
        ),
        if (sources.savings.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionLabel(
            icon: Icons.savings_outlined,
            title: 'Savings',
            subtitle: 'Use a savings account when accessible',
            color: AppColors.accountSaving,
          ),
          const SizedBox(height: 10),
          ...sources.savings.map(
            (account) => _SourceCard(
              account: account,
              amountLabel:
                  '${account.currency} ${(sources.balances[account.id] ?? 0).toStringAsFixed(0)}',
              secondaryLabel:
                  'Available ${(sources.balances[account.id] ?? 0).toStringAsFixed(0)}',
              selected: controller.selectedAccountId == account.id,
              accent: AppColors.accountSaving,
              onTap: () => _selectFullAccount(account),
            ),
          ),
        ],
        if (sources.prepaid.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionLabel(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Prepaid Accounts',
            subtitle: 'Only prepaid products with a spendable balance',
            color: AppColors.accountWallet,
          ),
          const SizedBox(height: 10),
          ...sources.prepaid.map(
            (account) => _SourceCard(
              account: account,
              amountLabel:
                  '${account.currency} ${(sources.balances[account.id] ?? 0).toStringAsFixed(0)}',
              secondaryLabel:
                  'Available ${(sources.balances[account.id] ?? 0).toStringAsFixed(0)}',
              selected: controller.selectedAccountId == account.id,
              accent: AppColors.accountWallet,
              onTap: () => _selectFullAccount(account),
            ),
          ),
        ],
        if (sources.creditCards.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionLabel(
            icon: Icons.credit_card_outlined,
            title: 'Credit Cards',
            subtitle: 'Pay with credit — creates a card charge',
            color: Color(0xFFD36BFF),
          ),
          const SizedBox(height: 10),
          ...sources.creditCards.map(
            (card) => _CreditCardSourceCard(
              source: card,
              selected: controller.selectedAccountId == card.account.id,
              onTap: () => _selectCreditCard(card),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SheetFooter(
          actions: [
            FilledButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const AddAccountScreen(
                      sectionType: SectionType.liquidity,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Account'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstallment(
    _PaymentSources sources, {
    required bool downPayment,
  }) {
    final amount = _parseAmount();
    final financed = downPayment
        ? (amount - _downPayment).clamp(0.0, amount).toDouble()
        : amount;
    final monthly = _installmentMonths <= 0
        ? 0.0
        : financed / _installmentMonths;

    return Column(
      key: ValueKey(downPayment ? 'down-payment' : 'installment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF5A1F78).withOpacity(.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD36BFF).withOpacity(.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_month_outlined, color: Color(0xFFD36BFF)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  downPayment
                      ? 'Pay part now and finance the remaining amount.'
                      : 'Finance the purchase through a credit card or a financing provider.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (downPayment) ...[
          _AmountField(
            label: 'Down Payment',
            value: _downPayment,
            currency: 'EGP',
            onChanged: (value) => setState(() => _downPayment = value),
          ),
          const SizedBox(height: 12),
          _ReadOnlyMetric(
            label: 'Amount to Finance',
            value: 'EGP ${financed.toStringAsFixed(0)}',
          ),
        ] else ...[
          _ReadOnlyMetric(
            label: 'Purchase Amount',
            value: 'EGP ${amount.toStringAsFixed(0)}',
          ),
        ],
        const SizedBox(height: 14),
        _SectionLabel(
          icon: Icons.account_balance_outlined,
          title: downPayment
              ? 'Financing Provider / Credit Card'
              : 'Financing Provider',
          subtitle: 'This is a financing route, not an Account Source',
          color: const Color(0xFFD36BFF),
        ),
        const SizedBox(height: 10),
        ...sources.creditCards.map(
          (card) => _ChoiceCard(
            icon: Icons.credit_card_outlined,
            color: const Color(0xFFD36BFF),
            title: card.account.name,
            subtitle:
                'Credit Card • Available ${card.available.toStringAsFixed(0)} ${card.account.currency}',
            selected: _financingSourceId == card.account.id,
            onTap: () => setState(() => _financingSourceId = card.account.id),
          ),
        ),
        ...sources.financingProviders.map(
          (account) => _ChoiceCard(
            icon: Icons.account_balance_outlined,
            color: AppColors.debt,
            title: account.provider?.trim().isNotEmpty == true
                ? account.provider!
                : account.name,
            subtitle: 'Financing Provider',
            selected: _financingSourceId == account.id,
            onTap: () => setState(() => _financingSourceId = account.id),
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel(
          icon: Icons.timelapse_outlined,
          title: 'Installment Plan',
          subtitle: 'Choose the repayment term',
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [3, 6, 9, 12].map((months) {
            final selected = _installmentMonths == months;
            return ChoiceChip(
              label: Text('$months months'),
              selected: selected,
              onSelected: (_) => setState(() => _installmentMonths = months),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.cardSecondary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: selected ? AppColors.primary : Colors.white12,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ReadOnlyMetric(
                label: 'Monthly',
                value: 'EGP ${monthly.toStringAsFixed(0)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReadOnlyMetric(
                label: 'Financed',
                value: 'EGP ${financed.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _showInstallmentNotPersisted,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Color _accentForAccount(Account account) {
    switch (account.type) {
      case 'cash':
        return AppColors.accountCash;
      case 'wallet':
        return AppColors.accountWallet;
      case 'bank':
      case 'debitCard':
        return AppColors.accountBank;
      default:
        return AppColors.primary;
    }
  }
}

class _PaymentSources {
  const _PaymentSources({
    required this.liquidity,
    required this.savings,
    required this.prepaid,
    required this.creditCards,
    required this.financingProviders,
    required this.balances,
  });

  final List<Account> liquidity;
  final List<Account> savings;
  final List<Account> prepaid;
  final List<_CreditCardSource> creditCards;
  final List<Account> financingProviders;
  final Map<String, double> balances;
}

class _CreditCardSource {
  const _CreditCardSource({
    required this.account,
    required this.profile,
    required this.outstanding,
    required this.available,
  });

  final Account account;
  final CreditCardProfile profile;
  final double outstanding;
  final double available;
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.selected,
    required this.showInstallment,
    required this.onChanged,
  });

  final ExpensePaymentMode selected;
  final bool showInstallment;
  final ValueChanged<ExpensePaymentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final modes = [
      ExpensePaymentMode.fullPayment,
      if (showInstallment) ExpensePaymentMode.installment,
      if (showInstallment) ExpensePaymentMode.downPaymentInstallment,
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        children: modes.map((mode) {
          final isSelected = selected == mode;
          final label = switch (mode) {
            ExpensePaymentMode.fullPayment => 'Full Payment',
            ExpensePaymentMode.installment => 'Installment',
            ExpensePaymentMode.downPaymentInstallment =>
              'Down Payment + Installment',
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.account,
    required this.amountLabel,
    required this.secondaryLabel,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final Account account;
  final String amountLabel;
  final String secondaryLabel;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ChoiceCard(
      icon: _iconFor(account.type),
      color: accent,
      title: account.name,
      subtitle: '${_labelFor(account.type)} • $secondaryLabel',
      trailing: amountLabel,
      selected: selected,
      onTap: onTap,
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments_outlined;
      case 'bank':
        return Icons.account_balance_outlined;
      case 'debitCard':
        return Icons.credit_card_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  static String _labelFor(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'debitCard':
        return 'Debit Card';
      case 'wallet':
        return 'Wallet';
      default:
        return 'Account';
    }
  }
}

class _CreditCardSourceCard extends StatelessWidget {
  const _CreditCardSourceCard({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final _CreditCardSource source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD36BFF);
    return _ChoiceCard(
      icon: Icons.credit_card_outlined,
      color: accent,
      title: source.account.name,
      subtitle:
          'Credit Card • Available ${source.available.toStringAsFixed(0)} ${source.account.currency}',
      trailing: 'Limit ${source.profile.creditLimit.toString()}',
      selected: selected,
      onTap: onTap,
      bottom: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: source.profile.creditLimit.isZero
                    ? 0
                    : (source.outstanding / source.profile.creditLimit.toDouble())
                          .clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            source.profile.creditLimit.isZero
                ? '0% used'
                : '${(source.outstanding / source.profile.creditLimit.toDouble() * 100).clamp(0, 100).toStringAsFixed(0)}% used',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.bottom,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(.16)
                : AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : Colors.white.withOpacity(.08),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(.18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      trailing!,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected ? color : Colors.white38,
                    size: 24,
                  ),
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: 10),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyMetric extends StatelessWidget {
  const _ReadOnlyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatefulWidget {
  const _AmountField({
    required this.label,
    required this.value,
    required this.currency,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String currency;
  final ValueChanged<double> onChanged;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          widget.onChanged(double.tryParse(value) ?? 0);
        },
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          labelText: widget.label,
          labelStyle: const TextStyle(color: Colors.white54),
          suffixText: widget.currency,
          suffixStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

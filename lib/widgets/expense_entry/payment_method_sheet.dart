import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wafferly/controllers/transaction_entry_controller.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/theme/app_colors.dart';
import 'package:wafferly/widgets/bottom_sheet/sheet_footer.dart';
import 'package:wafferly/widgets/bottom_sheet/wafferly_bottom_sheet.dart';
import 'package:wafferly/screens/accounts/add_account/add_account_screen.dart';
import 'package:wafferly/models/enums/section_type.dart';
import 'package:wafferly/features/transactions/models/expense_payment_mode.dart';
import 'package:wafferly/config/category_config.dart';
import 'package:wafferly/config/category_type.dart';
import 'package:wafferly/l10n/app_localizations.dart';
import 'package:wafferly/widgets/expense_entry/member/member_selector.dart';

Future<void> showPaymentMethodSheet({
  required BuildContext context,
  required TransactionEntryController controller,
  ExpensePaymentMode? initialMode,
  bool installmentOnly = false,
}) async {
  final media = MediaQuery.of(context);
  final availableHeight = media.size.height - media.viewInsets.bottom;
  final compactScreen = media.size.width < 390;
  final maxSheetHeight =
      (availableHeight > 0 ? availableHeight : media.size.height) *
      (compactScreen ? .92 : .86);

  await WafferlyBottomSheet.show(
    context: context,
    // The sheet owns the scroll area so its height stays compact instead of
    // expanding with every account/card/financing row.
    scrollable: false,
    bodyPadding: EdgeInsets.fromLTRB(
      compactScreen ? 5 : 8,
      compactScreen ? 2 : 4,
      compactScreen ? 5 : 8,
      compactScreen ? 3 : 6,
    ),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: maxSheetHeight,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
          child: _PaymentMethodSheet(
            controller: controller,
            initialMode: initialMode,
            installmentOnly: installmentOnly,
          ),
        ),
      ),
    ),
  );
}

class _PaymentMethodSheet extends StatefulWidget {
  const _PaymentMethodSheet({
    required this.controller,
    this.initialMode,
    this.installmentOnly = false,
  });

  final TransactionEntryController controller;
  final ExpensePaymentMode? initialMode;
  final bool installmentOnly;

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  late Future<_PaymentSources> _future;
  ExpensePaymentMode _mode = ExpensePaymentMode.fullPayment;
  String? _financingSourceId;
  int _installmentMonths = 6;
  double _downPayment = 0;
  String? _downPaymentAccountId;
  late DateTime _firstDueDate;
  bool _firstDueDateManuallySet = false;
  final GlobalKey _memberAnchorKey = GlobalKey();
  bool _savingPlan = false;
  // Recurring execution is not wired into this workflow yet; this state currently
  // drives the control only and is intentionally not persisted as a schedule.
  bool _isRecurringEnabled = false;

  TransactionEntryController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _mode = widget.installmentOnly
        ? (widget.initialMode ?? controller.expensePaymentMode)
        : ExpensePaymentMode.fullPayment;
    _future = _loadSources();
    _downPayment = 0;
    _firstDueDate = _addMonths(controller.selectedDate, 1);
    _future.then((sources) {
      if (!mounted || _financingSourceId != null || sources.creditCards.isEmpty) {
        return;
      }
      final card = sources.creditCards.first;
      setState(() {
        _financingSourceId = card.account.id;
        _firstDueDate = _defaultFirstDueDate(card);
      });
    });
  }

  double _parseAmount() => double.tryParse(controller.amount) ?? 0;

  String _currencyCode(_PaymentSources sources) {
    final selected = Hive.box<Account>('accounts').get(_financingSourceId);
    if (selected != null && selected.currency.trim().isNotEmpty) {
      return selected.currency;
    }
    if (sources.creditCards.isNotEmpty) {
      return sources.creditCards.first.account.currency;
    }
    return controller.currentCurrency;
  }

  DateTime _defaultFirstDueDate(_CreditCardSource card) {
    // Use the card's saved payment due day as the default in the month
    // following the purchase date. Issuer-specific posting rules can differ,
    // so the user can still override this date.
    final transactionDate = controller.selectedDate;
    final nextMonth = DateTime(transactionDate.year, transactionDate.month + 1, 1);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final configuredDueDay = card.profile.paymentDueDay;
    final day = (configuredDueDay ?? transactionDate.day)
        .clamp(1, lastDay)
        .toInt();
    return DateTime(nextMonth.year, nextMonth.month, day);
  }

  void _selectFinancingCard(_CreditCardSource card) {
    setState(() {
      _financingSourceId = card.account.id;
      _firstDueDateManuallySet = false;
      _firstDueDate = _defaultFirstDueDate(card);
    });
  }

  void _selectFinancingProvider(Account account) {
    setState(() {
      _financingSourceId = account.id;
      _firstDueDateManuallySet = false;
      _firstDueDate = _addMonths(controller.selectedDate, 1);
    });
  }

  Future<void> _pickTransactionDate(_PaymentSources sources) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    controller.setSelectedDate(picked);
    setState(() {
      if (!_firstDueDateManuallySet) {
        _CreditCardSource? selectedCard;
        for (final card in sources.creditCards) {
          if (card.account.id == _financingSourceId) {
            selectedCard = card;
            break;
          }
        }
        _firstDueDate = selectedCard == null
            ? _addMonths(picked, 1)
            : _defaultFirstDueDate(selectedCard);
      }
    });
  }

  Future<void> _pickMember() async {
    await MemberSelector.show(
      context: context,
      members: controller.availableMembers,
      selectedMemberId: controller.selectedMemberId,
      onSelected: (memberId) => setState(() => controller.selectMember(memberId)),
      anchorKey: _memberAnchorKey,
    );
  }

  Future<void> _editNote() async {
    final savedNote = await showDialog<String>(
      context: context,
      builder: (_) => _TransactionNoteDialog(initialNote: controller.note),
    );
    if (savedNote == null || !mounted) return;
    setState(() => controller.setNote(savedNote));
  }


  Future<_PaymentSources> _loadSources() async {
    // Read directly from the canonical Hive Account box. This keeps the
    // payment-method sheet independent from the legacy liquidity-only
    // `availableAccounts` getter used by the old selector.
    final accounts = Hive.box<Account>('accounts').values
        .where(
          (a) =>
              a.bookId == 'default' &&
              !a.isArchived &&
              a.id != 'liability.temp_debt',
        )
        .toList();

    final liquidity = accounts
        .where((a) => a.group == AccountGroup.liquidity)
        .toList();
    final savings = accounts
        .where((a) => a.group == AccountGroup.savings)
        .toList();
    final prepaid = accounts
        .where((a) => a.type == 'prepaid')
        .toList();
    // Credit cards are identified by their canonical technical type.
    // Do not depend on the liability group here, so old/migrated cards still
    // appear in the Expense payment source list.
    final creditCardAccounts = accounts
        .where((a) => a.type == 'creditCard')
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

  Future<void> _executeInstallmentPlan() async {
    final amount = _parseAmount();

    debugPrint(
      'INSTALLMENT BUTTON PRESSED: '
      'mode=$_mode amount=$amount '
      'financingSourceId=$_financingSourceId '
      'downPayment=$_downPayment '
      'downPaymentAccountId=$_downPaymentAccountId '
      'months=$_installmentMonths '
      'firstDueDate=$_firstDueDate',
    );

    // A Credit Card is currently the only financing source backed by a
    // complete execution boundary in the Financial Engine. If the user has
    // one available and did not explicitly change it, use it automatically.
    if (_financingSourceId == null) {
      try {
        final sources = await _future;
        if (sources.creditCards.isNotEmpty) {
          _financingSourceId = sources.creditCards.first.account.id;
        }
      } catch (error) {
        debugPrint('INSTALLMENT SOURCE LOAD ERROR: $error');
      }
    }

    if (_financingSourceId == null) {
      _showInstallmentError('Choose a financing option first.');
      return;
    }

    if (amount <= 0) {
      _showInstallmentError('Enter the purchase amount first.');
      return;
    }

    if (_mode == ExpensePaymentMode.downPaymentInstallment) {
      if (_downPayment <= 0) {
        _showInstallmentError('Enter a down payment amount.');
        return;
      }
      if (_downPayment >= amount) {
        _showInstallmentError(
          'Down payment must be less than the purchase amount.',
        );
        return;
      }
    }

    final sourceAccount =
        Hive.box<Account>('accounts').get(_financingSourceId);

    if (sourceAccount == null) {
      _showInstallmentError(
        'The selected financing source is unavailable.',
      );
      return;
    }

    if (sourceAccount.type != 'creditCard') {
      _showInstallmentError(
        'Financing-company installment execution is not connected yet. '
        'Credit Card installment execution is supported now.',
      );
      return;
    }

    if (_mode == ExpensePaymentMode.downPaymentInstallment &&
        (_downPaymentAccountId == null ||
            _downPaymentAccountId!.isEmpty)) {
      _showInstallmentError(
        'Select a valid source for the down payment.',
      );
      return;
    }

    final financed = _mode == ExpensePaymentMode.downPaymentInstallment
        ? (amount - _downPayment).clamp(0.0, amount).toDouble()
        : amount;

    debugPrint(
      'INSTALLMENT EXECUTE: '
      'creditCard=${sourceAccount.id} '
      'purchase=$amount '
      'downPayment=${_mode == ExpensePaymentMode.downPaymentInstallment ? _downPayment : 0} '
      'financed=$financed '
      'months=$_installmentMonths',
    );

    setState(() => _savingPlan = true);

    try {
      // Keep the controller's payment mode synchronized with the sheet.
      // This is important for downstream transaction state and reset logic.
      controller.setExpensePaymentMode(_mode);

      final result = await controller.saveCreditCardInstallment(
        creditCardAccountId: sourceAccount.id,
        installmentCount: _installmentMonths,
        firstDueDate: _firstDueDate,
        downPayment: _mode == ExpensePaymentMode.downPaymentInstallment
            ? _downPayment
            : 0,
        downPaymentAccountId:
            _mode == ExpensePaymentMode.downPaymentInstallment
            ? _downPaymentAccountId
            : null,
      );

      debugPrint(
        'INSTALLMENT RESULT: '
        'success=${result.success} '
        'action=${result.action} '
        'error=${result.errorMessage}',
      );

      if (!mounted) return;

      if (result.success) {
        // The controller owns the financial write. Only dismiss the sheet
        // after it explicitly reports success.
        Navigator.of(context).pop(true);
        return;
      }

      _showInstallmentError(
        result.errorMessage ?? 'Installment could not be completed.',
      );
    } catch (error, stackTrace) {
      debugPrint('INSTALLMENT EXECUTION ERROR: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _showInstallmentError(
        'Installment could not be saved: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _savingPlan = false);
      }
    }
  }

  void _showInstallmentError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
        ),
      );
  }

  DateTime _addMonths(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(target.year, target.month, day);
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

        // Preselect the first executable Credit Card financing source.
        // This is only a UI default; the actual financial write remains in
        // TransactionEntryController.
        if (_financingSourceId == null && sources.creditCards.isNotEmpty) {
          _financingSourceId = sources.creditCards.first.account.id;
          if (!_firstDueDateManuallySet) {
            _firstDueDate = _defaultFirstDueDate(sources.creditCards.first);
          }
        }

        if (!canInstallment && _mode != ExpensePaymentMode.fullPayment) {
          _mode = ExpensePaymentMode.fullPayment;
        }

        if (widget.installmentOnly) {
          if (!canInstallment) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No installment financing source is available.',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResponsivePaymentSheetHeader(
                title: 'Installment Details',
                subtitle: 'Configure how this purchase will be financed',
                compactSubtitle: 'Configure financing',
                icon: Icons.bar_chart_rounded,
                onClose: () => Navigator.pop(context),
              ),
              SizedBox(height: MediaQuery.sizeOf(context).width < 430 ? 5 : 10),
              _buildInstallment(
                sources,
                downPayment: _mode == ExpensePaymentMode.downPaymentInstallment,
                showDownPaymentToggle: true,
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResponsivePaymentSheetHeader(
              title: 'Payment Method',
              subtitle: 'How do you want to pay for this purchase?',
              compactSubtitle: 'Choose how to pay',
              icon: Icons.account_balance_wallet_outlined,
              onClose: () => Navigator.pop(context),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).width < 430 ? 6 : 10),
            // Full Payment is now a dedicated screen. Installment has its own
            // entry point and sheet, so do not show mode tabs here.
            _buildFullPayment(sources),
          ],
        );
      },
    );
  }

  Widget _buildFullPayment(_PaymentSources sources) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final sectionGap = compact ? 8.0 : 14.0;
    final cardGap = compact ? 6.0 : 10.0;
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
        SizedBox(height: cardGap),
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
          SizedBox(height: sectionGap),
          const _SectionLabel(
            icon: Icons.savings_outlined,
            title: 'Savings',
            subtitle: 'Use a savings account when accessible',
            color: AppColors.accountSaving,
          ),
          SizedBox(height: cardGap),
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
          SizedBox(height: sectionGap),
          const _SectionLabel(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Prepaid Accounts',
            subtitle: 'Only prepaid products with a spendable balance',
            color: AppColors.accountWallet,
          ),
          SizedBox(height: cardGap),
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
          SizedBox(height: sectionGap),
          const _SectionLabel(
            icon: Icons.credit_card_outlined,
            title: 'Credit Cards',
            subtitle: 'Pay with credit — creates a card charge',
            color: Color(0xFFD36BFF),
          ),
          SizedBox(height: cardGap),
          ...sources.creditCards.map(
            (card) => _CreditCardSourceCard(
              source: card,
              selected: controller.selectedAccountId == card.account.id,
              onTap: () => _selectCreditCard(card),
            ),
          ),
        ],
        SizedBox(height: compact ? 8 : 12),
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
    bool showDownPaymentToggle = false,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final amount = _parseAmount();
    final currencyCode = _currencyCode(sources);
    final financed = downPayment
        ? (amount - _downPayment).clamp(0.0, amount).toDouble()
        : amount;
    final monthly = _installmentMonths <= 0
        ? 0.0
        : financed / _installmentMonths;

    final eligibleDownPaymentAccounts = [
      ...sources.liquidity.where(
        (account) => account.currency == currencyCode &&
            (sources.balances[account.id] ?? 0) >= _downPayment,
      ),
      ...sources.savings.where(
        (account) => account.currency == currencyCode &&
            (sources.balances[account.id] ?? 0) >= _downPayment,
      ),
      ...sources.prepaid.where(
        (account) => account.currency == currencyCode &&
            (sources.balances[account.id] ?? 0) >= _downPayment,
      ),
    ];

    final eligibleDownPaymentCards = sources.creditCards.where((card) {
      if (card.account.currency != currencyCode) return false;
      final isSameFinancingCard = card.account.id == _financingSourceId;
      final requiredCredit = isSameFinancingCard ? amount : _downPayment;
      return card.available + 0.000001 >= requiredCredit;
    }).toList();

    if (downPayment && _downPaymentAccountId != null) {
      final stillEligible =
          eligibleDownPaymentAccounts.any((a) => a.id == _downPaymentAccountId) ||
          eligibleDownPaymentCards.any((c) => c.account.id == _downPaymentAccountId);
      if (!stillEligible) _downPaymentAccountId = null;
    }

    if (downPayment && _downPaymentAccountId == null) {
      if (eligibleDownPaymentAccounts.isNotEmpty) {
        _downPaymentAccountId = eligibleDownPaymentAccounts.first.id;
      } else if (eligibleDownPaymentCards.isNotEmpty) {
        _downPaymentAccountId = eligibleDownPaymentCards.first.account.id;
      }
    }

    return Column(
      key: ValueKey(downPayment ? 'down-payment' : 'installment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPurchaseSummary(context, sources),
        SizedBox(height: compact ? 4 : 6),
        _buildTransactionContextRow(sources),
        SizedBox(height: compact ? 5 : 8),
        const _CompactSectionTitle(
          icon: Icons.account_balance_outlined,
          title: 'Financing Source',
          color: Color(0xFFD36BFF),
        ),
        const SizedBox(height: 6),
        if (sources.creditCards.isNotEmpty)
          ...sources.creditCards.map(
            (card) => _CompactSourceCard(
              icon: Icons.credit_card_outlined,
              color: const Color(0xFFD36BFF),
              title: card.account.name,
              subtitle:
                  'Available ${card.available.toStringAsFixed(0)} ${card.account.currency}  •  Limit ${card.profile.creditLimit.toDouble().toStringAsFixed(0)}',
              selected: _financingSourceId == card.account.id,
              onTap: () => _selectFinancingCard(card),
            ),
          ),
        if (sources.financingProviders.isNotEmpty)
          ...sources.financingProviders.map(
            (account) => _CompactSourceCard(
              icon: Icons.account_balance_outlined,
              color: AppColors.debt,
              title: account.provider?.trim().isNotEmpty == true
                  ? account.provider!
                  : account.name,
              subtitle: 'Financing Provider',
              selected: _financingSourceId == account.id,
              onTap: () => _selectFinancingProvider(account),
            ),
          ),
        SizedBox(height: compact ? 4 : 6),
        Row(
          children: [
            Expanded(
              child: _CompactSectionTitle(
                icon: Icons.timelapse_outlined,
                title: compact ? 'First Installment' : 'First Installment Due',
                color: AppColors.primary,
              ),
            ),
            _CompactDateButton(
              date: _firstDueDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: _firstDueDate,
                );
                if (picked != null && mounted) {
                  setState(() {
                    _firstDueDate = picked;
                    _firstDueDateManuallySet = true;
                  });
                }
              },
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2),
          child: Text('Installment Plan', style: TextStyle(color: Colors.white60, fontSize: compact ? 10 : 10.5, fontWeight: FontWeight.w700)),
        ),
        Row(
          children: [
            ..._quickInstallmentPeriods.map((months) {
              final selected = _installmentMonths == months;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () => setState(() => _installmentMonths = months),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      height: compact ? 33 : 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.cardSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.white10,
                        ),
                      ),
                      child: Text(
                        '$months',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: InkWell(
                onTap: _showInstallmentPlanPicker,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: compact ? 33 : 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _quickInstallmentPeriods.contains(_installmentMonths)
                      ? AppColors.cardSecondary
                      : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _quickInstallmentPeriods.contains(_installmentMonths)
                          ? Colors.white10
                          : AppColors.primary,
                    ),
                  ),
                  child: Text(
                    _quickInstallmentPeriods.contains(_installmentMonths)
                        ? 'More'
                        : '${_installmentMonths}m',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 9.5 : 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showDownPaymentToggle) ...[
          SizedBox(height: compact ? 5 : 8),
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: AppColors.cardSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Down Payment',
                        style: TextStyle(color: Colors.white, fontSize: compact ? 11.5 : 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Transform.scale(
                      scale: compact ? 0.84 : 1,
                      child: Switch.adaptive(
                      value: downPayment,
                      onChanged: (enabled) {
                        setState(() {
                          _mode = enabled
                              ? ExpensePaymentMode.downPaymentInstallment
                              : ExpensePaymentMode.installment;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    ),
                  ],
                ),
                if (downPayment) ...[
                  SizedBox(height: compact ? 4 : 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _AmountField(
                          label: 'Down Payment',
                          value: _downPayment,
                          currency: currencyCode,
                          onChanged: (value) => setState(() => _downPayment = value),
                        ),
                      ),
                      SizedBox(width: compact ? 5 : 8),
                      Expanded(
                        child: _CompactSourcePicker(
                          title: 'Pay From',
                          selectedTitle: _selectedDownPaymentSourceTitle(sources, _downPaymentAccountId),
                          onTap: () => _showDownPaymentSourcePicker(sources, eligibleDownPaymentAccounts, eligibleDownPaymentCards),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  _InlineMoneySummary(
                    label: 'Amount to Finance',
                    value: '$currencyCode ${financed.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: compact ? 3 : 5),
                  _InlineMoneySummary(
                    label: 'Monthly Installment',
                    value: '$currencyCode ${monthly.toStringAsFixed(2)}',
                  ),
                ],
              ],
            ),
          ),
        ],
        SizedBox(height: compact ? 5 : 8),
        if (!downPayment)
          Row(
            children: [
              Expanded(
                child: _ReadOnlyMetric(
                  label: 'Amount to Finance',
                  value: '$currencyCode ${financed.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: compact ? 5 : 8),
              Expanded(
                child: _ReadOnlyMetric(
                  label: 'Monthly Installment',
                  value: '$currencyCode ${monthly.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        SizedBox(height: compact ? 5 : 8),
        SizedBox(
          width: double.infinity,
          height: compact ? 42 : 46,
          child: FilledButton(
            onPressed: _savingPlan ? null : _executeInstallmentPlan,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _savingPlan ? 'Saving…' : 'Continue',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseSummary(BuildContext context, _PaymentSources sources) {
    final t = AppLocalizations.of(context)!;
    final amount = _parseAmount();
    final currencyCode = _currencyCode(sources);
    final categoryName = _categoryDisplayName(t);
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Row(
      children: [
        Expanded(
          flex: compact ? 13 : 11,
          child: _CompactInfoCard(
            icon: Icons.payments_outlined,
            label: compact ? 'Amount' : 'Purchase Amount',
            value: '$currencyCode ${amount.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 10,
          child: _CompactInfoCard(
            icon: Icons.category_outlined,
            label: 'Category',
            value: categoryName,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: compact ? 4 : 6,
          child: _CompactNoteCard(note: controller.note, onTap: _editNote),
        ),
      ],
    );
  }

  Widget _buildTransactionContextRow(_PaymentSources sources) {
    final members = controller.availableMembers;
    dynamic selectedMember;
    for (final member in members) {
      if (member.id == controller.selectedMemberId) {
        selectedMember = member;
        break;
      }
    }
    final memberName = selectedMember?.name as String? ?? 'Me';

    final dateChip = _CompactContextChip(
      icon: Icons.calendar_today_outlined,
      label: controller.transactionDateLabel,
      onTap: () => _pickTransactionDate(sources),
    );
    final memberChip = _CompactContextChip(
      key: _memberAnchorKey,
      icon: Icons.person_outline_rounded,
      label: memberName,
      onTap: _pickMember,
    );

    // Keep these controls visibly separate and editable at every screen size.
    // The recurring switch is presentation-only until recurring execution is wired.
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 350;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: dateChip),
                const SizedBox(width: 6),
                Expanded(child: memberChip),
              ],
            ),
            const SizedBox(height: 6),
            if (narrow) ...[
              _ContextToggleCard(
                icon: Icons.repeat_rounded,
                label: 'Recurring',
                valueLabel: _isRecurringEnabled ? 'On' : 'Off',
                value: _isRecurringEnabled,
                accent: AppColors.primary,
                onChanged: (value) => setState(() => _isRecurringEnabled = value),
              ),
              const SizedBox(height: 6),
              _ContextToggleCard(
                icon: Icons.star_rounded,
                label: 'Exceptional',
                valueLabel: controller.isExceptional ? 'On' : 'Off',
                value: controller.isExceptional,
                accent: const Color(0xFFFFD166),
                onChanged: (_) => setState(() => controller.toggleExceptional()),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _ContextToggleCard(
                      icon: Icons.repeat_rounded,
                      label: 'Recurring',
                      valueLabel: _isRecurringEnabled ? 'On' : 'Off',
                      value: _isRecurringEnabled,
                      accent: AppColors.primary,
                      onChanged: (value) => setState(() => _isRecurringEnabled = value),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ContextToggleCard(
                      icon: Icons.star_rounded,
                      label: 'Exceptional',
                      valueLabel: controller.isExceptional ? 'On' : 'Off',
                      value: controller.isExceptional,
                      accent: const Color(0xFFFFD166),
                      onChanged: (_) => setState(() => controller.toggleExceptional()),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  String _categoryDisplayName(AppLocalizations t) {
    final id = controller.selectedCategoryId;
    if (id.isEmpty) return 'Not selected';
    for (final category in getCategories(CategoryType.expense)) {
      if (category.id == id) return category.resolveTitle(t);
      final sub = category.subCategories;
      if (sub != null) {
        for (final item in sub) {
          if (item.id == id) return item.title(t);
        }
      }
    }
    return id;
  }

  String _selectedDownPaymentSourceTitle(
    _PaymentSources sources,
    String? id,
  ) {
    if (id == null || id.isEmpty) return 'Select source';
    for (final account in [
      ...sources.liquidity,
      ...sources.savings,
      ...sources.prepaid,
    ]) {
      if (account.id == id) return account.name;
    }
    for (final card in sources.creditCards) {
      if (card.account.id == id) return card.account.name;
    }
    return 'Select source';
  }

  static const List<int> _quickInstallmentPeriods = [3, 6, 9, 12, 18, 24];
  static const List<int> _commonInstallmentPeriods = [
    3, 6, 9, 12, 18, 24, 36, 48, 60,
  ];
  static const int _maxCustomInstallmentMonths = 60;

  Future<void> _showInstallmentPlanPicker() async {
    final chosenMonths = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final screen = MediaQuery.sizeOf(sheetContext);
        final compact = screen.width < 390;
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screen.height * (compact ? .78 : .72),
                maxWidth: 430,
              ),
              child: _InstallmentPlanPickerSheet(
                initialMonths: _installmentMonths,
                periods: _commonInstallmentPeriods,
                maxMonths: _maxCustomInstallmentMonths,
              ),
            ),
          ),
        );
      },
    );
    if (chosenMonths != null && mounted) {
      setState(() => _installmentMonths = chosenMonths);
    }
  }

  Future<void> _showDownPaymentSourcePicker(
    _PaymentSources sources,
    List<Account> accounts,
    List<_CreditCardSource> cards,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            children: [
              const _CompactSheetHandle(),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4, bottom: 8),
                child: Text(
                  'Pay Down Payment From',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              ...accounts.map(
                (account) => _CompactSourceCard(
                  icon: account.group == AccountGroup.savings
                      ? Icons.savings_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  title: account.name,
                  subtitle:
                      'Available ${(sources.balances[account.id] ?? 0).toStringAsFixed(0)} ${account.currency}',
                  selected: _downPaymentAccountId == account.id,
                  onTap: () {
                    setState(() => _downPaymentAccountId = account.id);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
              ...cards.map(
                (card) => _CompactSourceCard(
                  icon: Icons.credit_card_outlined,
                  color: const Color(0xFFD36BFF),
                  title: card.account.name,
                  subtitle:
                      'Available ${card.available.toStringAsFixed(0)} ${card.account.currency}',
                  selected: _downPaymentAccountId == card.account.id,
                  onTap: () {
                    setState(() => _downPaymentAccountId = card.account.id);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        );
      },
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


class _CompactSheetHandle extends StatelessWidget {
  const _CompactSheetHandle();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 38,
          height: 4,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );
}

class _CompactInfoCard extends StatelessWidget {
  const _CompactInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      height: compact ? 48 : 52,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: compact ? 14 : 17),
          SizedBox(width: compact ? 4 : 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white54, fontSize: compact ? 8.5 : 9.5),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 11.5 : 13,
                      fontWeight: FontWeight.w800,
                    ),
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

class _CompactNoteCard extends StatelessWidget {
  const _CompactNoteCard({required this.note, required this.onTap});
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: MediaQuery.sizeOf(context).width < 430 ? 48 : 52,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.note_alt_outlined, color: Colors.white70, size: 16),
              const SizedBox(height: 1),
              Text(
                note.trim().isEmpty ? 'Note' : 'Note ✓',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
}

class _ContextToggleCard extends StatelessWidget {
  const _ContextToggleCard({
    required this.icon,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String valueLabel;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: EdgeInsetsDirectional.only(
        start: compact ? 9 : 12,
        end: compact ? 4 : 8,
        top: 5,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: value ? accent.withOpacity(.12) : AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? accent.withOpacity(.65) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 16 : 18, color: accent),
          SizedBox(width: compact ? 5 : 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valueLabel,
                  maxLines: 1,
                  style: TextStyle(
                    color: value ? accent : Colors.white54,
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: compact ? .78 : .88,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactContextChip extends StatelessWidget {
  const _CompactContextChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.muted = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? const Color(0xFFFFD166) : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(.14) : AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accent.withOpacity(.65) : Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: muted ? Colors.white38 : accent),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted ? Colors.white54 : Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMoneySummary extends StatelessWidget {
  const _InlineMoneySummary({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white60, fontSize: compact ? 9.5 : 10.5))),
          const SizedBox(width: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight,
            child: Text(value, maxLines: 1, softWrap: false,
              style: TextStyle(color: Colors.white, fontSize: compact ? 10.5 : 12, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _CompactSectionTitle extends StatelessWidget {
  const _CompactSectionTitle({required this.icon, required this.title, required this.color});
  final IconData icon;
  final String title;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      );
}

class _CompactSourceCard extends StatelessWidget {
  const _CompactSourceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 3 : 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: compact ? 46 : 54,
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(.16) : AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: selected ? color : Colors.white10,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 28 : 32,
                height: compact ? 28 : 32,
                decoration: BoxDecoration(color: color.withOpacity(.13), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: compact ? 15 : 17),
              ),
              SizedBox(width: compact ? 7 : 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: compact ? 12 : 12.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white54, fontSize: compact ? 8.8 : 9.5)),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                color: selected ? color : Colors.white30, size: compact ? 17 : 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactToggle extends StatelessWidget {
  const _CompactToggle({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
            Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
          ],
        ),
      );
}

class _CompactDateButton extends StatelessWidget {
  const _CompactDateButton({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: compact ? 29 : 32,
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, color: AppColors.primary, size: compact ? 13 : 15),
            const SizedBox(width: 4),
            Text('${date.day}/${date.month}/${date.year}',
              style: TextStyle(color: Colors.white70, fontSize: compact ? 9.5 : 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CompactSourcePicker extends StatelessWidget {
  const _CompactSourcePicker({required this.title, required this.selectedTitle, required this.onTap});
  final String title;
  final String selectedTitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: compact ? 52 : 62,
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
        decoration: BoxDecoration(
          color: AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.payments_outlined, color: AppColors.primary, size: compact ? 14 : 17),
            SizedBox(width: compact ? 5 : 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white54, fontSize: compact ? 8.5 : 9.5)),
                  const SizedBox(height: 2),
                  Text(selectedTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: compact ? 10 : 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Icon(Icons.expand_more, color: Colors.white38, size: compact ? 16 : 18),
          ],
        ),
      ),
    );
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
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: compact ? 18 : 21),
        SizedBox(width: compact ? 7 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:  TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white54, fontSize: compact ? 10 : 12),
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
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(compact ? 6 : 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(.16)
                : AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(compact ? 12 : 18),
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
                    width: compact ? 30 : 36,
                    height: compact ? 30 : 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: compact ? 16 : 19),
                  ),
                  const SizedBox(width: 8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: compact ? 8.8 : 9.5,
                            height: 1.05,
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
                    size: 21,
                  ),
                ],
              ),
              if (bottom != null && !compact) ...[
                const SizedBox(height: 8),
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
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 7 : 10),
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white54, fontSize: compact ? 9.5 : 11)),
          SizedBox(height: compact ? 2 : 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, softWrap: false,
              style: TextStyle(color: Colors.white, fontSize: compact ? 13 : 16, fontWeight: FontWeight.w800))),
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
    _controller = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 5 : 8),
      decoration: BoxDecoration(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) => widget.onChanged(double.tryParse(value) ?? 0),
        style: TextStyle(color: Colors.white, fontSize: compact ? 16 : 18, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          labelText: widget.label,
          labelStyle: TextStyle(color: Colors.white54, fontSize: compact ? 9.5 : 12),
          suffixText: widget.currency,
          suffixStyle: TextStyle(color: Colors.white70, fontSize: compact ? 11 : 14, fontWeight: FontWeight.w700),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}


class _ResponsivePaymentSheetHeader extends StatelessWidget {
  const _ResponsivePaymentSheetHeader({
    required this.title,
    required this.subtitle,
    required this.compactSubtitle,
    required this.icon,
    required this.onClose,
  });
  final String title;
  final String subtitle;
  final String compactSubtitle;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: compact ? 20 : 24),
        SizedBox(width: compact ? 7 : 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: compact ? 16 : 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(compact ? compactSubtitle : subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white60, fontSize: compact ? 10.5 : 12)),
            ],
          ),
        ),
        SizedBox(
          width: compact ? 30 : 36,
          height: compact ? 30 : 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: Colors.white60, size: compact ? 19 : 22),
          ),
        ),
      ],
    );
  }
}

class _TransactionNoteDialog extends StatefulWidget {
  const _TransactionNoteDialog({required this.initialNote});
  final String initialNote;

  @override
  State<_TransactionNoteDialog> createState() => _TransactionNoteDialogState();
}

class _TransactionNoteDialogState extends State<_TransactionNoteDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSecondary,
      title: const Text('Transaction Note', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _noteController,
        autofocus: true,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Add a note',
          hintStyle: TextStyle(color: Colors.white38),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_noteController.text.trim()), child: const Text('Save')),
      ],
    );
  }
}

class _InstallmentPlanPickerSheet extends StatefulWidget {
  const _InstallmentPlanPickerSheet({
    required this.initialMonths,
    required this.periods,
    required this.maxMonths,
  });

  final int initialMonths;
  final List<int> periods;
  final int maxMonths;

  @override
  State<_InstallmentPlanPickerSheet> createState() =>
      _InstallmentPlanPickerSheetState();
}

class _InstallmentPlanPickerSheetState
    extends State<_InstallmentPlanPickerSheet> {
  late final TextEditingController _monthsController;
  late int _draftMonths;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _draftMonths = widget.initialMonths;
    _monthsController = TextEditingController(
      text: widget.periods.contains(widget.initialMonths)
          ? ''
          : widget.initialMonths.toString(),
    );
  }

  @override
  void dispose() {
    _monthsController.dispose();
    super.dispose();
  }

  void _apply() {
    final raw = _monthsController.text.trim();
    final parsed = raw.isEmpty ? _draftMonths : int.tryParse(raw);
    if (parsed == null || parsed < 1 || parsed > widget.maxMonths) {
      setState(() {
        _validationMessage =
            'Enter a whole number from 1 to ${widget.maxMonths}.';
      });
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 8 : 10,
        compact ? 12 : 16,
        compact ? 12 : 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CompactSheetHandle(),
          Row(
            children: [
              Icon(Icons.timelapse_outlined, color: AppColors.primary,
                size: compact ? 19 : 21),
              SizedBox(width: compact ? 7 : 9),
              Expanded(
                child: Text('Select Installment Plan', maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white,
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800)),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white60),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            compact ? 'Choose or enter months.' : 'Choose a preset or enter a custom number of months.',
            style: TextStyle(color: Colors.white60, fontSize: compact ? 10.5 : 12),
          ),
          SizedBox(height: compact ? 9 : 14),
          Wrap(
            spacing: compact ? 5 : 8,
            runSpacing: compact ? 5 : 8,
            children: widget.periods.map((months) {
              final selected = _monthsController.text.trim().isEmpty &&
                  _draftMonths == months;
              return ChoiceChip(
                label: Text('$months mo'),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _draftMonths = months;
                    _validationMessage = null;
                    _monthsController.clear();
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.cardSecondary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: compact ? 10.5 : 12,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : Colors.white12,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          SizedBox(height: compact ? 10 : 16),
          Text('Custom Number of Months', style: TextStyle(
            color: Colors.white, fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w800)),
          SizedBox(height: compact ? 5 : 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _monthsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  onChanged: (_) => setState(() => _validationMessage = null),
                  style: TextStyle(color: Colors.white,
                    fontSize: compact ? 13 : 15, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Enter months (1–${widget.maxMonths})',
                    hintStyle: TextStyle(color: Colors.white38,
                      fontSize: compact ? 10.5 : 13),
                    suffixText: 'months',
                    filled: true,
                    fillColor: AppColors.cardSecondary,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: compact ? 9 : 12,
                      vertical: compact ? 10 : 13,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              SizedBox(
                height: compact ? 42 : 46,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          if (_validationMessage != null) ...[
            const SizedBox(height: 5),
            Text(_validationMessage!, style: const TextStyle(
              color: Color(0xFFFF8A80), fontSize: 11)),
          ],
          SizedBox(height: compact ? 7 : 12),
          Container(
            padding: EdgeInsets.all(compact ? 7 : 10),
            decoration: BoxDecoration(
              color: AppColors.cardSecondary,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.white54, size: compact ? 15 : 17),
                SizedBox(width: compact ? 6 : 8),
                Expanded(
                  child: Text(
                    'Confirm that the selected duration is supported by your bank or financing agreement.',
                    style: TextStyle(color: Colors.white60,
                      fontSize: compact ? 9.5 : 11, height: 1.3),
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

import 'package:flutter/material.dart';

import '../../../application/credit_card/credit_card_account_application_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/account.dart';
import '../../../models/enums/section_type.dart';
import '../../../shared/widgets/wafferly_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../add_account/add_account_screen.dart';

/// Selects the active bank account that will be stored on the credit-card profile.
/// It returns the selected Account to both the initial flow and the Change action.
class CreditCardBankAccountSelectionScreen extends StatefulWidget {
  const CreditCardBankAccountSelectionScreen({
    super.key,
    this.initialSelectedAccountId,
  });

  final String? initialSelectedAccountId;

  @override
  State<CreditCardBankAccountSelectionScreen> createState() =>
      _CreditCardBankAccountSelectionScreenState();
}

class _CreditCardBankAccountSelectionScreenState
    extends State<CreditCardBankAccountSelectionScreen> {
  final _applicationService = CreditCardAccountApplicationService();
  final _searchController = TextEditingController();
  late List<Account> _accounts;
  String? _selectedAccountId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _accounts = _applicationService.getActiveBankAccounts();
    _selectedAccountId = widget.initialSelectedAccountId;
    if (!_accounts.any((account) => account.id == _selectedAccountId)) {
      _selectedAccountId = null;
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  List<Account> get _filteredAccounts {
    if (_query.isEmpty) return _accounts;
    return _accounts.where((account) {
      final values = <String>[
        account.name,
        account.provider ?? '',
        account.currency,
        account.accountNumber ?? '',
      ];
      return values.any((value) => value.toLowerCase().contains(_query));
    }).toList();
  }

  Future<void> _createBankAccount() async {
    final previousIds = _applicationService
        .getActiveBankAccounts()
        .map((account) => account.id)
        .toSet();

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddAccountScreen(
          sectionType: SectionType.liquidity,
          initialAccountType: 'bank',
        ),
      ),
    );
    if (created != true || !mounted) return;

    final refreshed = _applicationService.getActiveBankAccounts();
    final newlyCreated = refreshed
        .where((account) => !previousIds.contains(account.id))
        .toList();

    setState(() {
      _accounts = refreshed;
      if (newlyCreated.isNotEmpty) {
        _selectedAccountId = newlyCreated.last.id;
      } else if (!_accounts.any((a) => a.id == _selectedAccountId)) {
        _selectedAccountId = null;
      }
    });

    // Continue the interrupted credit-card flow immediately after a new bank
    // account is created. A non-bank account does not satisfy the requirement.
    if (newlyCreated.isNotEmpty) {
      Navigator.of(context).pop(newlyCreated.last);
    }
  }

  void _continue() {
    final selectedId = _selectedAccountId;
    if (selectedId == null) return;

    // Re-read from the application boundary so an archived account cannot be
    // returned as the selected relationship if it changed while this screen was open.
    final currentActive = _applicationService.getActiveBankAccounts();
    Account? selected;
    for (final account in currentActive) {
      if (account.id == selectedId) {
        selected = account;
        break;
      }
    }
    if (selected == null) {
      setState(() {
        _accounts = currentActive;
        _selectedAccountId = null;
      });
      return;
    }
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final m = ResponsiveMetrics.of(context);
    final t = AppLocalizations.of(context)!;
    final filtered = _filteredAccounts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          t.selectBankAccountTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: m.typography.title,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _accounts.isEmpty
                ? _buildEmptyState(m, t)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          m.spacing(16),
                          m.space.xs,
                          m.spacing(16),
                          m.space.sm,
                        ),
                        child: Text(
                          t.selectBankAccountMessage,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: m.typography.body,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: m.spacing(16)),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: t.searchBankAccounts,
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: AppColors.card,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: m.space.md,
                              vertical: m.space.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(m.radius.lg),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: m.space.sm),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: m.spacing(16)),
                        child: Text(
                          t.accounts,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: m.typography.body,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: m.space.xs),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(m.space.lg),
                                  child: Text(
                                    t.noAccountsAvailable,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: m.typography.body,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  m.spacing(16),
                                  m.space.xs,
                                  m.spacing(16),
                                  m.space.md,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: m.space.xs),
                                itemBuilder: (context, index) {
                                  final account = filtered[index];
                                  final selected = account.id == _selectedAccountId;
                                  return _BankAccountTile(
                                    metrics: m,
                                    account: account,
                                    selected: selected,
                                    onTap: () => setState(
                                      () => _selectedAccountId = account.id,
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          m.spacing(16),
                          0,
                          m.spacing(16),
                          m.space.sm,
                        ),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _createBankAccount,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(t.createNewBankAccount),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (_accounts.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(
                m.spacing(16),
                m.space.sm,
                m.spacing(16),
                m.space.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .25),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: .06)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: WafferlyButton(
                  onPressed: _continue,
                  enabled: _selectedAccountId != null &&
                      _accounts.any((account) => account.id == _selectedAccountId),
                  title: t.continueLabel,
                  icon: Icons.arrow_forward_rounded,
                  backgroundColor: const Color(0xFF35E0B5),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ResponsiveMetrics m, AppLocalizations t) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(m.spacing(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: m.size(108),
              height: m.size(108),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .2),
                ),
              ),
              child: Icon(
                Icons.account_balance_outlined,
                color: AppColors.accent,
                size: m.icon.hero,
              ),
            ),
            SizedBox(height: m.space.lg),
            Text(
              t.noBankAccountsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: m.typography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: m.space.sm),
            Text(
              t.noBankAccountsMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: m.typography.body,
                height: 1.45,
              ),
            ),
            SizedBox(height: m.space.lg),
            WafferlyButton(
              onPressed: _createBankAccount,
              title: t.createBankAccount,
              icon: Icons.add_rounded,
              backgroundColor: const Color(0xFF35E0B5),
              foregroundColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _BankAccountTile extends StatelessWidget {
  const _BankAccountTile({
    required this.metrics,
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final ResponsiveMetrics metrics;
  final Account account;
  final bool selected;
  final VoidCallback onTap;

  String _accountSubtitle() {
    final provider = account.provider?.trim();
    final number = account.accountNumber?.trim();
    final lastDigits = number == null || number.isEmpty
        ? null
        : (number.length <= 4 ? number : number.substring(number.length - 4));
    final parts = <String>[];
    if (provider != null && provider.isNotEmpty && provider != account.name) {
      parts.add(provider);
    }
    if (lastDigits != null && lastDigits.isNotEmpty) {
      parts.add('•••• $lastDigits');
    }
    if (parts.isEmpty) parts.add(account.currency);
    return parts.join('  •  ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(metrics.radius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(metrics.space.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(metrics.radius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: metrics.size(46),
                height: metrics.size(46),
                decoration: BoxDecoration(
                  color: AppColors.accountBank.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(metrics.radius.md),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  size: metrics.icon.medium,
                ),
              ),
              SizedBox(width: metrics.space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: metrics.typography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: metrics.space.xs),
                    Text(
                      _accountSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: metrics.typography.caption,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: metrics.space.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    account.currency,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: metrics.typography.caption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: metrics.space.xs),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppColors.primary : AppColors.textHint,
                    size: metrics.icon.medium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

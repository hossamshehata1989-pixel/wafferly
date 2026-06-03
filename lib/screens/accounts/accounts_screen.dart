// lib/screens/accounts/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import '../../services/account_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/balance_service.dart';
import 'add_account/add_account_screen.dart';
import '../../models/enums/section_type.dart';
import '../../utils/account_mapper.dart';
import '../../services/virtual_saving_service.dart';
import '../savings/virtual_saving_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService _accountService = AccountService();
  static const String TEMP_DEBT_ACCOUNT_NAME = 'دين مؤقت';

  void _showSimpleTempDebtDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.tempDebtTitle),
        content: Text(t.tempDebtDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.incomeLinkingComingSoon)),
              );
            },
            child: Text(t.settleNow),
          ),
        ],
      ),
    );
  }

  SectionType _getSectionTypeFromString(String sectionType) {
    switch (sectionType) {
      case 'asset':
        return SectionType.asset;
      case 'liability':
        return SectionType.liability;
      case 'investment':
        return SectionType.investment;
      case 'receivable':
        return SectionType.receivable;
      case 'saving':
        return SectionType.saving;
      default:
        return SectionType.asset;
    }
  }

  SectionType _getSectionTypeFromAccount(Account account) {
    if (account.group == AccountGroup.savings) {
      return SectionType.saving;
    }
    if (account.group == AccountGroup.investments) {
      return SectionType.investment;
    }
    if (account.group == AccountGroup.receivable) {
      return SectionType.receivable;
    }
    if (account.group == AccountGroup.liabilities) {
      return SectionType.liability;
    }
    return SectionType.asset;
  }

  void _addAccount(String sectionType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(
          sectionType: _getSectionTypeFromString(sectionType),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _editAccount(Account account) {
    if (account.name == TEMP_DEBT_ACCOUNT_NAME) {
      _showSimpleTempDebtDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(
          sectionType: _getSectionTypeFromAccount(account),
          accountToEdit: account,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  double _calculateNetWorth(
    List<Account> accounts,
    BalanceService balanceService,
  ) {
    double assets = 0, liabilities = 0;
    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);
      if (acc.nature == AccountNature.asset) {
        assets += balance;
      } else if (acc.nature == AccountNature.liability) {
        liabilities += balance.abs();
      }
    }
    return assets - liabilities;
  }

  double _calculateTotalByNature(
    List<Account> accounts,
    BalanceService balanceService,
    AccountNature nature,
  ) {
    double total = 0;
    for (final acc in accounts.where((a) => a.nature == nature)) {
      final balance = balanceService.getBalance(acc.id);
      if (nature == AccountNature.liability) {
        total += balance.abs();
      } else {
        total += balance;
      }
    }
    return total;
  }

  double _calculateSectionTotal(
    List<Account> accounts,
    BalanceService balanceService,
  ) {
    double total = 0;
    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);
      if (acc.nature == AccountNature.liability) {
        total += balance.abs();
      } else {
        total += balance;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final balanceService = BalanceService();
    final isSmallPhone = screenWidth < 380;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          t.accounts,
          style: TextStyle(
            fontSize: isSmallPhone ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ValueListenableBuilder(
        valueListenable: _accountService.box.listenable(),
        builder: (context, Box<Account> box, _) {
          final accounts = _accountService.getAllActiveAccounts();

          final virtualSavingService = VirtualSavingService();
          final virtualSavingBalance = virtualSavingService.getTotalBalance();
          final virtualSavingItemsCount = virtualSavingService.getItemsCount();

          // DEBUG مؤقت
          for (final a in accounts) {
            print(
              'DEBUG: ${a.name} | '
              'type=${a.type} | '
              'storedGroup=${a.group} | '
              'resolvedGroup=${resolveGroup(a.type)}',
            );
          }

          final netWorth = _calculateNetWorth(accounts, balanceService);
          final totalAssets = _calculateTotalByNature(
            accounts,
            balanceService,
            AccountNature.asset,
          );
          final totalLiabilities = _calculateTotalByNature(
            accounts,
            balanceService,
            AccountNature.liability,
          );

          final moneyHave = accounts
              .where((a) => a.group == AccountGroup.liquidity)
              .toList();
          final investments = accounts
              .where((a) => a.group == AccountGroup.investments)
              .toList();
          final liabilities = accounts
              .where((a) => a.group == AccountGroup.liabilities)
              .toList();
          final receivables = accounts
              .where((a) => a.group == AccountGroup.receivable)
              .toList();
          final savings = accounts
              .where((a) => a.group == AccountGroup.savings)
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildNetWorthCard(
                  netWorth,
                  totalAssets,
                  totalLiabilities,
                  isTablet,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildSection(
                t.moneyYouHave,
                Icons.account_balance_wallet,
                moneyHave,
                balanceService,
                Colors.green,
                isTablet,
                isLargeTablet,
                () => _addAccount('asset'),
                true,
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSavingsSection(
                      savings,
                      balanceService,
                      isTablet,
                      isLargeTablet,
                      virtualSavingBalance,
                      virtualSavingItemsCount,
                    ),
                  ],
                ),
              ),
              _buildSection(
                t.investments,
                Icons.trending_up,
                investments,
                balanceService,
                Colors.orange,
                isTablet,
                isLargeTablet,
                () => _addAccount('investment'),
                true,
              ),
              _buildSection(
                t.moneyYouOwe,
                Icons.credit_card,
                liabilities,
                balanceService,
                Colors.red,
                isTablet,
                isLargeTablet,
                () => _addAccount('liability'),
                true,
              ),
              _buildSection(
                t.moneyYouWillGet,
                Icons.handshake,
                receivables,
                balanceService,
                Colors.blue,
                isTablet,
                isLargeTablet,
                () => _addAccount('receivable'),
                true,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "accountsFab",
        onPressed: () => _addAccount('asset'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNetWorthCard(
    double netWorth,
    double totalAssets,
    double totalLiabilities,
    bool isTablet,
  ) {
    final t = AppLocalizations.of(context)!;
    final formatter = NumberFormat("#,###");
    final isNegative = netWorth < 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative
              ? [Colors.red.shade900, Colors.red.shade800]
              : [Colors.blue.shade900, Colors.purple.shade800],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t.netWorth,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isTablet ? 14 : 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (isTablet)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t.last30DaysGrowth,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${formatter.format(netWorth.abs().toInt())} ${t.currency}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 42 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNetWorthDetail(
                t.moneyYouHave,
                totalAssets,
                Colors.green,
                isTablet,
              ),
              const SizedBox(width: 16),
              _buildNetWorthDetail(
                t.moneyYouOwe,
                totalLiabilities,
                Colors.red,
                isTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthDetail(
    String label,
    double amount,
    Color color,
    bool isTablet,
  ) {
    final t = AppLocalizations.of(context)!;
    final formatter = NumberFormat("#,###");
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 12 : 8,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white54,
                fontSize: isTablet ? 12 : 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatter.format(amount.toInt())} ${t.currency}',
              style: TextStyle(
                color: color,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Account> accounts,
    BalanceService balanceService,
    Color color,
    bool isTablet,
    bool isLargeTablet,
    VoidCallback onAddTap,
    bool showAddButton,
  ) {
    final t = AppLocalizations.of(context)!;
    final sectionTotal = _calculateSectionTotal(accounts, balanceService);
    final formatter = NumberFormat("#,###");
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${formatter.format(sectionTotal.toInt())} ${t.currency}',
                  style: TextStyle(
                    color: color,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (showAddButton)
                  GestureDetector(
                    onTap: onAddTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: color, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      '${accounts.length} Accounts',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(int itemCount, bool isTablet, bool isLargeTablet) {
    if (isLargeTablet) return 4;
    if (isTablet) return 3;
    if (itemCount <= 2) return 2;
    return 2;
  }

  double _getChildAspectRatio(
    int itemCount,
    bool isTablet,
    bool isLargeTablet,
  ) {
    if (isLargeTablet) return 1.2;
    if (isTablet) return 1.3;
    if (itemCount <= 2) {
      return 1.6;
    }
    return 1.3;
  }

  Widget _buildAccountCard(
    Account account,
    double balance,
    double percentage,
    Color color,
    bool isTablet,
    VoidCallback onTap,
    AppLocalizations t,
  ) {
    final formatter = NumberFormat("#,###");
    final isLiability = account.nature == AccountNature.liability;
    final displayBalance = isLiability ? balance.abs() : balance;
    final balanceColor = isLiability
        ? Colors.redAccent
        : (balance < 0 ? Colors.redAccent : color);
    final isTempDebtAccount = account.name == TEMP_DEBT_ACCOUNT_NAME;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 12 : 8),
        decoration: BoxDecoration(
          color: isTempDebtAccount
              ? Colors.grey.shade900.withOpacity(0.6)
              : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTempDebtAccount
                ? Colors.grey.withOpacity(0.5)
                : color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getAccountIcon(account.type),
                  color: isTempDebtAccount ? Colors.grey.shade500 : color,
                  size: isTablet ? 28 : 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.name,
                    style: TextStyle(
                      color: isTempDebtAccount
                          ? Colors.grey.shade400
                          : Colors.white,
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isTempDebtAccount)
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${formatter.format(displayBalance.toInt())} ${account.currency}',
              style: TextStyle(
                color: balanceColor,
                fontSize: isTablet ? 18 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            if (!isTempDebtAccount) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: color,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${percentage.toStringAsFixed(0)}% ${t.ofSection}',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: isTablet ? 10 : 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.attach_money;
      case 'bank':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'creditCard':
        return Icons.credit_card;
      case 'loan':
        return Icons.money_off;
      case 'investment':
        return Icons.trending_up;
      case 'gold':
        return Icons.workspace_premium;
      case 'stocks':
        return Icons.show_chart;
      case 'lent':
        return Icons.handshake;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildSavingsSection(
    List<Account> savings,
    BalanceService balanceService,
    bool isTablet,
    bool isLargeTablet,
    double virtualSavingBalance,
    int virtualSavingItemsCount,
  ) {
    final t = AppLocalizations.of(context)!;

    final savingsTotal = _calculateSectionTotal(savings, balanceService);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.savings,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '${NumberFormat("#,###").format(savingsTotal.toInt())} ${t.currency}',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: () => _addAccount('saving'),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.teal, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Normal savings grid
          const SizedBox(height: 16),
          // Virtual saving card
          Column(
            children: [
              _buildSavingsSummaryTile(
                'Real Saving',
                savings.where((a) => a.type == 'realSaving').length,
              ),

              const SizedBox(height: 12),

              _buildSavingsSummaryTile(
                'Saving Circle',
                savings
                    .where((a) => a.type == 'savingCircle' || a.type == 'rosca')
                    .length,
              ),

              const SizedBox(height: 12),

              _buildSavingsSummaryTile(
                'Virtual Saving',
                virtualSavingItemsCount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsSummaryTile(String title, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '$count Accounts',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
        ],
      ),
    );
  }
}

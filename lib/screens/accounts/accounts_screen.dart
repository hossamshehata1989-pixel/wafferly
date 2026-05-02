import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/account_enums.dart';
import '../../services/account_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/balance_service.dart';
import 'add_account/add_account_screen.dart';

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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.close)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.incomeLinkingComingSoon)));
            },
            child: Text(t.settleNow),
          ),
        ],
      ),
    );
  }

  SectionType _getSectionTypeFromString(String sectionType) {
    switch (sectionType) {
      case 'asset': return SectionType.asset;
      case 'liability': return SectionType.liability;
      case 'investment': return SectionType.investment;
      case 'receivable': return SectionType.receivable;
      default: return SectionType.asset;
    }
  }

  SectionType _getSectionTypeFromAccount(Account account) {
    if (account.natureEnum == AccountNature.asset) {
      if (account.group == AccountGroup.investments) return SectionType.investment;
      return SectionType.asset;
    } else {
      return SectionType.liability;
    }
  }

  void _addAccount(String sectionType) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAccountScreen(sectionType: _getSectionTypeFromString(sectionType)))).then((_) { if (mounted) setState(() {}); });
  }

  void _editAccount(Account account) {
    if (account.name == TEMP_DEBT_ACCOUNT_NAME) {
      _showSimpleTempDebtDialog();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAccountScreen(sectionType: _getSectionTypeFromAccount(account), accountToEdit: account))).then((_) { if (mounted) setState(() {}); });
  }

  double _calculateNetWorth(List<Account> accounts, BalanceService balanceService) {
    double assets = 0, liabilities = 0;
    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);
      if (acc.natureEnum == AccountNature.asset) assets += balance;
      else liabilities += balance.abs();
    }
    return assets - liabilities;
  }

  double _calculateTotalByNature(List<Account> accounts, BalanceService balanceService, AccountNature nature) {
    double total = 0;
    for (final acc in accounts.where((a) => a.natureEnum == nature)) {
      final balance = balanceService.getBalance(acc.id);
      if (nature == AccountNature.liability) total += balance.abs();
      else total += balance;
    }
    return total;
  }

  double _calculateSectionTotal(List<Account> accounts, BalanceService balanceService) {
    double total = 0;
    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);
      if (acc.natureEnum == AccountNature.liability) total += balance.abs();
      else total += balance;
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
        title: Text(t.accounts, style: TextStyle(fontSize: isSmallPhone ? 18 : 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ValueListenableBuilder(
        valueListenable: _accountService.box.listenable(),
        builder: (context, Box<Account> box, _) {
          final accounts = _accountService.getAllActiveAccounts();
          final netWorth = _calculateNetWorth(accounts, balanceService);
          final totalAssets = _calculateTotalByNature(accounts, balanceService, AccountNature.asset);
          final totalLiabilities = _calculateTotalByNature(accounts, balanceService, AccountNature.liability);

          final moneyHave = accounts.where((a) => a.group == AccountGroup.moneyYouHave).toList();
          final investments = accounts.where((a) => a.group == AccountGroup.investments).toList();
          final liabilities = accounts.where((a) => a.group == AccountGroup.moneyYouOwe).toList();
          final receivables = accounts.where((a) => a.group == AccountGroup.moneyYouWillGet).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildNetWorthCard(netWorth, totalAssets, totalLiabilities, isTablet)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildSection(t.moneyYouHave, Icons.account_balance_wallet, moneyHave, balanceService, Colors.green, isTablet, isLargeTablet, () => _addAccount('asset'), true),
              _buildSection(t.investments, Icons.trending_up, investments, balanceService, Colors.orange, isTablet, isLargeTablet, () => _addAccount('investment'), true),
              _buildSection(t.moneyYouOwe, Icons.credit_card, liabilities, balanceService, Colors.red, isTablet, isLargeTablet, () => _addAccount('liability'), true),
              _buildSection(t.moneyYouWillGet, Icons.handshake, receivables, balanceService, Colors.blue, isTablet, isLargeTablet, () => _addAccount('receivable'), true),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _addAccount('asset'), backgroundColor: Colors.blue, child: const Icon(Icons.add, color: Colors.white)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNetWorthCard(double netWorth, double totalAssets, double totalLiabilities, bool isTablet) {
    final t = AppLocalizations.of(context)!;
    final formatter = NumberFormat("#,###");
    final isNegative = netWorth < 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isNegative ? [Colors.red.shade900, Colors.red.shade800] : [Colors.blue.shade900, Colors.purple.shade800]),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(t.netWorth, style: TextStyle(color: Colors.white70, fontSize: isTablet ? 14 : 12, letterSpacing: 1)),
            const Spacer(),
            if (isTablet) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(t.last30DaysGrowth, style: TextStyle(color: Colors.white70, fontSize: 12))),
          ]),
          const SizedBox(height: 16),
          Text('${formatter.format(netWorth.abs().toInt())} ${t.currency}', style: TextStyle(color: Colors.white, fontSize: isTablet ? 42 : 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            _buildNetWorthDetail(t.moneyYouHave, totalAssets, Colors.green, isTablet),
            const SizedBox(width: 16),
            _buildNetWorthDetail(t.moneyYouOwe, totalLiabilities, Colors.red, isTablet),
          ]),
        ],
      ),
    );
  }

  Widget _buildNetWorthDetail(String label, double amount, Color color, bool isTablet) {
    final t = AppLocalizations.of(context)!;
    final formatter = NumberFormat("#,###");
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8, horizontal: 12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white54, fontSize: isTablet ? 12 : 10)),
            const SizedBox(height: 4),
            Text('${formatter.format(amount.toInt())} ${t.currency}', style: TextStyle(color: color, fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Account> accounts, BalanceService balanceService, Color color, bool isTablet, bool isLargeTablet, VoidCallback onAddTap, bool showAddButton) {
    final t = AppLocalizations.of(context)!;
    final sectionTotal = _calculateSectionTotal(accounts, balanceService);
    final formatter = NumberFormat("#,###");
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3), width: 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: Colors.white, fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.bold))),
              Text('${formatter.format(sectionTotal.toInt())} ${t.currency}', style: TextStyle(color: color, fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (showAddButton) GestureDetector(onTap: onAddTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.add, color: color, size: 18))),
            ]),
            const SizedBox(height: 16),
            if (accounts.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(t.noAccountsYet, style: TextStyle(color: Colors.white38, fontSize: 14))))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accounts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getCrossAxisCount(accounts.length, isTablet, isLargeTablet),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: _getChildAspectRatio(accounts.length, isTablet, isLargeTablet),
                ),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final balance = balanceService.getBalance(account.id);
                  final percentage = sectionTotal > 0 ? (balance / sectionTotal) * 100 : 0.0;
                  return _buildAccountCard(account, balance, percentage, color, isTablet, () => _editAccount(account));
                },
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

  double _getChildAspectRatio(int itemCount, bool isTablet, bool isLargeTablet) {
    if (isLargeTablet) return 1.4;
    if (isTablet) return 1.5;
    if (itemCount <= 2) return 2.2;
    return 1.6;
  }

  Widget _buildAccountCard(Account account, double balance, double percentage, Color color, bool isTablet, VoidCallback onTap) {
    final t = AppLocalizations.of(context)!;
    final formatter = NumberFormat("#,###");
    final isLiability = account.natureEnum == AccountNature.liability;
    final displayBalance = isLiability ? balance.abs() : balance;
    final balanceColor = isLiability ? Colors.redAccent : (balance < 0 ? Colors.redAccent : color);
    final isTempDebtAccount = account.name == TEMP_DEBT_ACCOUNT_NAME;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 12 : 8),
        decoration: BoxDecoration(
          color: isTempDebtAccount ? Colors.grey.shade900.withOpacity(0.6) : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isTempDebtAccount ? Colors.grey.withOpacity(0.5) : color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(_getAccountIcon(account.type), color: isTempDebtAccount ? Colors.grey.shade500 : color, size: isTablet ? 28 : 22),
              const SizedBox(width: 8),
              Expanded(child: Text(account.name, style: TextStyle(color: isTempDebtAccount ? Colors.grey.shade400 : Colors.white, fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              if (isTempDebtAccount) Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
            ]),
            const SizedBox(height: 8),
            Text('${formatter.format(displayBalance.toInt())} ${account.currency}', style: TextStyle(color: balanceColor, fontSize: isTablet ? 18 : 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (!isTempDebtAccount) ...[
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.white.withOpacity(0.1), color: color, minHeight: 4)),
              const SizedBox(height: 4),
              Text('${percentage.toStringAsFixed(0)}% ${t.ofSection}', style: TextStyle(color: Colors.white54, fontSize: isTablet ? 10 : 8)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash': return Icons.attach_money;
      case 'bank': return Icons.account_balance;
      case 'wallet': return Icons.account_balance_wallet;
      case 'creditCard': return Icons.credit_card;
      case 'loan': return Icons.money_off;
      case 'investment': return Icons.trending_up;
      case 'gold': return Icons.workspace_premium;
      case 'stocks': return Icons.show_chart;
      case 'lent': return Icons.handshake;
      default: return Icons.account_balance_wallet;
    }
  }
}
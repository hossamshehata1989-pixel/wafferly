// lib/screens/accounts/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/account_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/balance_service.dart';

// ✅ معلق مؤقتاً لأن الملف مش موجود
// import 'add_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService _accountService = AccountService();

  @override
  void initState() {
    super.initState();
  }

  // ==========================================
  // ✅ دوال الحسابات
  // ==========================================
  
  double _calculateNetWorth(List<Account> accounts, BalanceService balanceService) {
    double assets = 0;
    double liabilities = 0;
    
    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);
      if (acc.nature == 'asset') {
        assets += balance;
      } else if (acc.nature == 'liability') {
        liabilities += balance.abs();
      }
    }
    return assets - liabilities;
  }

  double _calculateTotalByNature(List<Account> accounts, BalanceService balanceService, String nature) {
    double total = 0;
    for (final acc in accounts.where((a) => a.nature == nature)) {
      final balance = balanceService.getBalance(acc.id);
      if (nature == 'liability') {
        total += balance.abs();
      } else {
        total += balance;
      }
    }
    return total;
  }

  double _calculateSectionTotal(List<Account> accounts, BalanceService balanceService) {
    double total = 0;
    for (final acc in accounts) {
      final balance = balanceService.getBalance(acc.id);
      if (acc.nature == 'liability') {
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
      appBar: _buildAppBar(t, isSmallPhone),
      body: ValueListenableBuilder(
        valueListenable: _accountService.box.listenable(),
        builder: (context, Box<Account> box, _) {
          final accounts = _accountService.getAllAccounts();
          
          // ✅ إذا لم يكن هناك حسابات، اعرض رسالة للمستخدم
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 80, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    "No accounts yet",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the + button to add your first account",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          
          final netWorth = _calculateNetWorth(accounts, balanceService);
          final totalAssets = _calculateTotalByNature(accounts, balanceService, 'asset');
          final totalLiabilities = _calculateTotalByNature(accounts, balanceService, 'liability');
          
          final moneyHave = accounts.where((a) => 
            a.nature == 'asset' && a.type != 'investment' && a.type != 'lent').toList();
          final investments = accounts.where((a) => a.type == 'investment').toList();
          final liabilities = accounts.where((a) => a.nature == 'liability').toList();
          final receivables = accounts.where((a) => a.type == 'lent').toList();
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildNetWorthCard(
                  netWorth: netWorth,
                  totalAssets: totalAssets,
                  totalLiabilities: totalLiabilities,
                  isTablet: isTablet,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildResponsiveSection(
                title: t.moneyYouHave,
                icon: Icons.account_balance_wallet,
                accounts: moneyHave,
                balanceService: balanceService,
                color: Colors.green,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
                onAddTap: () => _addAccount(context, 'asset'),
              ),
              _buildResponsiveSection(
                title: t.investments,
                icon: Icons.trending_up,
                accounts: investments,
                balanceService: balanceService,
                color: Colors.orange,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
                onAddTap: () => _addAccount(context, 'investment'),
              ),
              _buildResponsiveSection(
                title: t.moneyYouOwe,
                icon: Icons.credit_card,
                accounts: liabilities,
                balanceService: balanceService,
                color: Colors.red,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
                onAddTap: () => _addAccount(context, 'liability'),
              ),
              _buildResponsiveSection(
                title: t.moneyYouWillGet,
                icon: Icons.handshake,
                accounts: receivables,
                balanceService: balanceService,
                color: Colors.blue,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
                onAddTap: () => _addAccount(context, 'receivable'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(t),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  AppBar _buildAppBar(AppLocalizations t, bool isSmallPhone) {
    return AppBar(
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
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
      ],
    );
  }
  
  Widget _buildNetWorthCard({
    required double netWorth,
    required double totalAssets,
    required double totalLiabilities,
    required bool isTablet,
  }) {
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              const Icon(Icons.account_balance, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'NET WORTH',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isTablet ? 14 : 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (isTablet)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Last 30 days: +8%',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${formatter.format(netWorth.abs().toInt())} EGP',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 42 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNetWorthDetail('Assets', totalAssets, Colors.green, isTablet),
              const SizedBox(width: 16),
              _buildNetWorthDetail('Debts', totalLiabilities, Colors.red, isTablet),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetWorthDetail(String label, double amount, Color color, bool isTablet) {
    final formatter = NumberFormat("#,###");
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white54, fontSize: isTablet ? 12 : 10),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatter.format(amount.toInt())} EGP',
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
  
  Widget _buildResponsiveSection({
    required String title,
    required IconData icon,
    required List<Account> accounts,
    required BalanceService balanceService,
    required Color color,
    required bool isTablet,
    required bool isLargeTablet,
    required VoidCallback onAddTap,
  }) {
    if (accounts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final sectionTotal = _calculateSectionTotal(accounts, balanceService);
    final formatter = NumberFormat("#,###");
    
    int crossAxisCount;
    double childAspectRatio;
    
    if (isLargeTablet) {
      crossAxisCount = 4;
      childAspectRatio = 1.4;
    } else if (isTablet) {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    } else if (accounts.length <= 2) {
      crossAxisCount = 2;
      childAspectRatio = 2.2;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 1.6;
    }
    
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
                  '${formatter.format(sectionTotal.toInt())} EGP',
                  style: TextStyle(
                    color: color,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: accounts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final account = accounts[index];
                final balance = balanceService.getBalance(account.id);
                final percentage = sectionTotal > 0 ? (balance / sectionTotal) * 100 : 0.0;
                
                return _buildAccountCard(
                  account: account,
                  balance: balance,
                  percentage: percentage,
                  color: color,
                  isTablet: isTablet,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountCard({
    required Account account,
    required double balance,
    required double percentage,
    required Color color,
    required bool isTablet,
  }) {
    final formatter = NumberFormat("#,###");
    final isLiability = account.nature == 'liability';
    final displayBalance = isLiability ? balance.abs() : balance;
    final balanceColor = isLiability ? Colors.redAccent : (balance < 0 ? Colors.redAccent : color);
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _getAccountIcon(account.type),
                color: color,
                size: isTablet ? 28 : 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
            '${percentage.toStringAsFixed(0)}% of section',
            style: TextStyle(
              color: Colors.white54,
              fontSize: isTablet ? 10 : 8,
            ),
          ),
        ],
      ),
    );
  }
  
  // ✅ زر الإضافة - استخدم الـ Quick Dialog
  Widget _buildFAB(AppLocalizations t) {
    return FloatingActionButton(
      onPressed: () {
        _showAddAccountDialog(context);
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
  
  void _addAccount(BuildContext context, String sectionType) {
    _showQuickAddDialog(context, sectionType);
  }
  
  void _showQuickAddDialog(BuildContext context, String sectionType) {
    final nameController = TextEditingController();
    String selectedType = _getDefaultTypeForSection(sectionType);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Account', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Account Name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              dropdownColor: const Color(0xFF2E2E2E),
              style: const TextStyle(color: Colors.white),
              items: _getTypeOptionsForSection(sectionType).map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                selectedType = value!;
              },
              decoration: const InputDecoration(
                labelText: 'Account Type',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _saveAccountQuick(name, selectedType, sectionType);
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  String _getDefaultTypeForSection(String sectionType) {
    switch (sectionType) {
      case 'asset': return 'Cash';
      case 'investment': return 'Investment';
      case 'liability': return 'Credit Card';
      case 'receivable': return 'Money Lent';
      default: return 'Cash';
    }
  }
  
  List<String> _getTypeOptionsForSection(String sectionType) {
    switch (sectionType) {
      case 'asset':
        return ['Cash', 'Bank', 'Wallet'];
      case 'investment':
        return ['Investment', 'Gold', 'Stocks'];
      case 'liability':
        return ['Credit Card', 'Loan'];
      case 'receivable':
        return ['Money Lent', 'ROSCA'];
      default:
        return ['Cash'];
    }
  }
  
  void _saveAccountQuick(String name, String typeDisplay, String sectionType) {
    String type = typeDisplay.toLowerCase().replaceAll(' ', '');
    String nature = 'asset';
    
    if (sectionType == 'liability') {
      nature = 'liability';
    } else if (sectionType == 'investment') {
      type = 'investment';
    } else if (sectionType == 'receivable') {
      type = 'lent';
    }
    
    final account = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: "personal",
      name: name,
      type: type,
      nature: nature,
      currency: "EGP",
      createdAt: DateTime.now(),
    );
    
    AccountService().addAccount(account);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added'), backgroundColor: Colors.green),
    );
  }
  
  void _showAddAccountDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add New Account', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 20),
            _buildAccountTypeTile('Cash', Icons.attach_money, Colors.green, 'cash', 'asset'),
            _buildAccountTypeTile('Bank', Icons.account_balance, Colors.blue, 'bank', 'asset'),
            _buildAccountTypeTile('Wallet', Icons.account_balance_wallet, Colors.orange, 'wallet', 'asset'),
            _buildAccountTypeTile('Credit Card', Icons.credit_card, Colors.red, 'creditCard', 'liability'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountTypeTile(String name, IconData icon, Color color, String type, String nature) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        _saveAccountQuick(name, type, nature == 'asset' ? 'asset' : 'liability');
      },
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
// lib/features/analysis/screens/analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';  // ✅ Changed from Expense
import '../../../l10n/app_localizations.dart';
import '../../../config/category_config.dart';
import '../models/time_period.dart';
import '../widgets/analysis_card.dart';
import '../widgets/category_details_section.dart';
import '../widgets/date_range_selector.dart';
import 'main_category_details_screen.dart';
import '../../../utils/category_helper.dart';
import '../../../services/transaction_service.dart';  // ✅ ADDED
import '../../../constants/transaction_constants.dart';  // ✅ ADDED

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  // Cache for analyzed data
  Map<String, double>? _cachedTotal;
  Map<String, double>? _cachedReal;
  Map<String, double>? _cachedExceptional;

  DateTime? _lastStartDate;
  DateTime? _lastEndDate;

  List<Transaction> _realExpenses = [];
  List<Transaction> _exceptionalExpenses = [];
  List<Transaction> _totalExpenses = [];
  
  double _realTotal = 0;
  double _exceptionalTotal = 0;
  double _totalExpensesAmount = 0;
  
  double _realChange = 0;
  double _exceptionalChange = 0;
  double _totalChange = 0;

  ValueNotifier<bool> _refreshNotifier = ValueNotifier(false);

  List<MainCategoryData>? _cachedRealList;
  List<MainCategoryData>? _cachedExceptionalList;
  List<MainCategoryData>? _cachedTotalList;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshNotifier.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate;
        break;
      case TimePeriod.weekly:
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case TimePeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case TimePeriod.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case TimePeriod.custom:
        break;
    }
    _loadData();
  }

  void _onPeriodChanged(TimePeriod period) {
    _selectedPeriod = period;
    _updateDateRange();
  }

  void _onDateRangeChanged(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    if (_selectedPeriod != TimePeriod.custom) {
      _selectedPeriod = TimePeriod.custom;
    }
    _loadData();
  }

  Map<String, double> _groupTransactionsByCategory(List<Transaction> list) {
    final result = <String, double>{};

    for (final t in list) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }

    return result;
  }

  void _loadData() {
  // ========== DEBUG TRACING START ==========
  print("\n" + "█" * 70);
  print("🔍 ANALYSIS SCREEN DEBUG TRACE");
  print("█" * 70);
  
  final ts = TransactionService.instance;
  
  // Get all transactions in date range
  final allTransactions = ts.getByDateRange(_startDate, _endDate);
  
  print("\n📅 DATE RANGE:");
  print("   Start: ${_startDate.toLocal()}");
  print("   End: ${_endDate.toLocal()}");
  
  print("\n📊 allTransactions:");
  print("   count = ${allTransactions.length}");
  print("   runtimeType = ${allTransactions.runtimeType}");
  
  if (allTransactions.isNotEmpty) {
    final sample = allTransactions.take(5).toList();
    print("   sample (first 5):");
    for (int i = 0; i < sample.length; i++) {
      final tx = sample[i];
      print("      [$i]");
      print("         type = '${tx.type}' (${tx.type.runtimeType})");
      print("         categoryId = '${tx.categoryId}' (${tx.categoryId.runtimeType})");
      print("         amount = ${tx.amount}");
      print("         isExceptional = ${tx.isExceptional}");
    }
    if (allTransactions.length > 5) {
      print("      ... and ${allTransactions.length - 5} more");
    }
  }
  
  // Filter by expense type
  final filteredTransactions = allTransactions
      .where((t) => t.type == TransactionType.expense)
      .toList();
  
  print("\n📊 filteredTransactions (where type == 'expense'):");
  print("   count = ${filteredTransactions.length}");
  print("   runtimeType = ${filteredTransactions.runtimeType}");
  
  final nonExpenseCount = allTransactions.length - filteredTransactions.length;
  if (nonExpenseCount > 0) {
    print("   ⚠️ Non-expense transactions: $nonExpenseCount");
    final otherTypes = allTransactions
        .where((t) => t.type != TransactionType.expense)
        .map((t) => "${t.type} (${t.type.runtimeType})")
        .toSet();
    print("   Types found: ${otherTypes.join(', ')}");
  }
  
  // Check categoryIds in filtered transactions
  final categoryIds = filteredTransactions.map((t) => t.categoryId).toSet();
  print("\n📊 categoryId analysis:");
  print("   unique categoryIds count = ${categoryIds.length}");
  print("   categoryIds = [${categoryIds.join(', ')}]");
  if (categoryIds.isNotEmpty) {
    print("   sample categoryId runtimeType = ${categoryIds.first.runtimeType}");
  }
  
  // ========== EXISTING CODE - SPLIT ==========
  _realExpenses = filteredTransactions.where((t) => !t.isExceptional).toList();
  _exceptionalExpenses = filteredTransactions.where((t) => t.isExceptional).toList();
  _totalExpenses = filteredTransactions;
  
  print("\n📊 Split by isExceptional:");
  print("   _realExpenses count = ${_realExpenses.length}");
  print("   _exceptionalExpenses count = ${_exceptionalExpenses.length}");
  print("   _totalExpenses count = ${_totalExpenses.length}");
  
  // ========== EXISTING CODE - GROUPING ==========
  final isSameRange = _lastStartDate == _startDate && _lastEndDate == _endDate;
  
  if (!isSameRange || _cachedReal == null) {
    _cachedReal = _groupTransactionsByCategory(_realExpenses);
    _cachedExceptional = _groupTransactionsByCategory(_exceptionalExpenses);
    _cachedTotal = _groupTransactionsByCategory(_totalExpenses);
    
    print("\n📊 GROUPING RESULTS (cache updated):");
    print("   _cachedReal:");
    print("      runtimeType = ${_cachedReal.runtimeType}");
    print("      entries count = ${_cachedReal?.length ?? 0}");
    if (_cachedReal != null && _cachedReal!.isNotEmpty) {
      print("      sample entries:");
      _cachedReal!.entries.take(5).forEach((entry) {
        print("         ${entry.key}: ${entry.value}");
      });
    } else {
      print("      ⚠️ _cachedReal is EMPTY or NULL");
    }
    
    print("   _cachedExceptional:");
    print("      runtimeType = ${_cachedExceptional.runtimeType}");
    print("      entries count = ${_cachedExceptional?.length ?? 0}");
    
    print("   _cachedTotal:");
    print("      runtimeType = ${_cachedTotal.runtimeType}");
    print("      entries count = ${_cachedTotal?.length ?? 0}");
    
    // Existing post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = AppLocalizations.of(context)!;
      
      _cachedRealList = _buildCategoryList(_cachedReal ?? {}, t);
      _cachedExceptionalList = _buildCategoryList(_cachedExceptional ?? {}, t);
      _cachedTotalList = _buildCategoryList(_cachedTotal ?? {}, t);
      
      print("\n📊 POST-FRAME CALLBACK:");
      print("   _cachedRealList count = ${_cachedRealList?.length ?? 0}");
      print("   _cachedExceptionalList count = ${_cachedExceptionalList?.length ?? 0}");
      print("   _cachedTotalList count = ${_cachedTotalList?.length ?? 0}");
      
      _refreshNotifier.value = !_refreshNotifier.value;
      print("   _refreshNotifier toggled");
    });
    
    _lastStartDate = _startDate;
    _lastEndDate = _endDate;
  } else {
    print("\n📊 CACHE HIT (using existing cache)");
    print("   _cachedReal entries = ${_cachedReal?.length ?? 0}");
    print("   _cachedExceptional entries = ${_cachedExceptional?.length ?? 0}");
    print("   _cachedTotal entries = ${_cachedTotal?.length ?? 0}");
  }
  
  // ========== EXISTING CODE - TOTALS ==========
  _realTotal = (_cachedReal ?? {}).values.fold<double>(0.0, (a, b) => a + b);
  _exceptionalTotal = (_cachedExceptional ?? {}).values.fold(0.0, (a, b) => a + b);
  _totalExpensesAmount = _realTotal + _exceptionalTotal;
  
  print("\n💰 TOTALS:");
  print("   _realTotal = $_realTotal");
  print("   _exceptionalTotal = $_exceptionalTotal");
  print("   _totalExpensesAmount = $_totalExpensesAmount");
  
  // ========== EXISTING CODE - CHANGE CALCULATION (kept as is) ==========
  final periodDays = _getPeriodDays();
  final previousStart = _startDate.subtract(Duration(days: periodDays));
  final previousEnd = _endDate.subtract(Duration(days: periodDays));
  
  final previousTransactions = ts.getByDateRange(previousStart, previousEnd);
  final previousExpenses = previousTransactions
      .where((t) => t.type == TransactionType.expense)
      .toList();
  
  final previousReal = previousExpenses
      .where((t) => !t.isExceptional)
      .fold(0.0, (sum, t) => sum + t.amount);
  final previousExceptional = previousExpenses
      .where((t) => t.isExceptional)
      .fold(0.0, (sum, t) => sum + t.amount);
  final previousTotal = previousReal + previousExceptional;
  
  _realChange = previousReal == 0 ? 0 : ((_realTotal - previousReal) / previousReal) * 100;
  _exceptionalChange = previousExceptional == 0 ? 0 : ((_exceptionalTotal - previousExceptional) / previousExceptional) * 100;
  _totalChange = previousTotal == 0 ? 0 : ((_totalExpensesAmount - previousTotal) / previousTotal) * 100;
  
  print("\n📈 CHANGES:");
  print("   _realChange = $_realChange%");
  print("   _exceptionalChange = $_exceptionalChange%");
  print("   _totalChange = $_totalChange%");
  print("█" * 70 + "\n");
  
  // ========== EXISTING CODE CONTINUES NORMALLY ==========
  // باقي الكود الأصلي بعد هذا لا يتغير
}

  int _getPeriodDays() {
    switch (_selectedPeriod) {
      case TimePeriod.daily: return 1;
      case TimePeriod.weekly: return 7;
      case TimePeriod.monthly: return 30;
      case TimePeriod.yearly: return 365;
      case TimePeriod.custom: return _endDate.difference(_startDate).inDays;
    }
  }

  String _formatCurrency(double amount) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final formatter = NumberFormat("#,###");
    if (isArabic) {
      return "${formatter.format(amount.toInt())} ج.م";
    } else {
      return "${formatter.format(amount.toInt())} EGP";
    }
  }

  List<MainCategoryData> _buildCategoryList(
    Map<String, double> data,
    AppLocalizations t,
  ) {
    final list = data.entries.map((entry) {
      return MainCategoryData(
        id: entry.key,
        name: getMainCategoryName(entry.key, t),
        total: entry.value,
      );
    }).toList();

    list.sort((a, b) => b.total.compareTo(a.total));

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedReal == null ||
        _cachedExceptional == null ||
        _cachedTotal == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return ValueListenableBuilder(
      valueListenable: _refreshNotifier,
      builder: (context, _, __) {
        final t = AppLocalizations.of(context)!;

        return Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          appBar: AppBar(
            title: Text(t.analysis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  DateRangeSelector(
                    selectedPeriod: _selectedPeriod,
                    startDate: _startDate,
                    endDate: _endDate,
                    onPeriodChanged: _onPeriodChanged,
                    onDateRangeChanged: _onDateRangeChanged,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      indicator: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                      tabs: [
                        Tab(text: t.totalExpenses),
                        Tab(text: t.realExpenses),
                        Tab(text: t.exceptionalExpenses),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                title: t.totalExpenses,
                amount: _totalExpensesAmount,
                change: _totalChange,
                color: Colors.blue,
                expenses: _totalExpenses,
              ),
              _buildTabContent(
                title: t.realExpenses,
                amount: _realTotal,
                change: _realChange,
                color: Colors.green,
                expenses: _realExpenses,
              ),
              _buildTabContent(
                title: t.exceptionalExpenses,
                amount: _exceptionalTotal,
                change: _exceptionalChange,
                color: Colors.orange,
                expenses: _exceptionalExpenses,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent({
    required String title,
    required double amount,
    required double change,
    required Color color,
    required List<Transaction> expenses,
  }) {
    final t = AppLocalizations.of(context)!;

    Map<String, double> mainCategoryData;

    if (expenses == _realExpenses) {
      mainCategoryData = _cachedReal ?? {};
    } else if (expenses == _exceptionalExpenses) {
      mainCategoryData = _cachedExceptional ?? {};
    } else {
      mainCategoryData = _cachedTotal ?? {};
    }
    
    List<MainCategoryData> categoryList;

    if (expenses == _realExpenses) {
      categoryList = _cachedRealList ?? [];
    } else if (expenses == _exceptionalExpenses) {
      categoryList = _cachedExceptionalList ?? [];
    } else {
      categoryList = _cachedTotalList ?? [];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryCard(
            title: title,
            amount: amount,
            change: change,
            color: color,
            formattedAmount: _formatCurrency(amount),
          ),
          const SizedBox(height: 24),
          CategoryDetailsSection(
            title: title,
            mainCategoriesData: categoryList,
            color: color,
            onSubCategoryTap: (categoryId, categoryName) {
              _showMainCategoryDetails(categoryId, categoryName, expenses);
            },
          ),
        ],
      ),
    );
  }

  void _showMainCategoryDetails(String categoryId, String categoryName, List<Transaction> allExpenses) {
    final filteredExpenses = allExpenses.where((e) => e.categoryId == categoryId).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainCategoryDetailsScreen(
          mainCategoryId: categoryId,
          mainCategoryName: categoryName,
          expenses: filteredExpenses,  // ✅ Changed from expenses to transactions
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }
}

// ✅ Updated SummaryCard (no changes needed, works with any data)
class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final double change;
  final Color color;
  final String formattedAmount;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.change,
    required this.color,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            formattedAmount,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (change != 0)
                Icon(
                  change > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: change > 0 ? Colors.red : Colors.green,
                ),
              if (change != 0) const SizedBox(width: 4),
              Text(
                change == 0
                    ? "0% ${t.vsLastPeriod}"
                    : "${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}% ${t.vsLastPeriod}",
                style: TextStyle(
                  color: change > 0
                      ? Colors.red
                      : (change < 0 ? Colors.green : Colors.white54),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
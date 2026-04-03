// lib/features/analysis/screens/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/expense.dart';
import '../../../l10n/app_localizations.dart';
import '../../../config/category_config.dart';
import '../models/time_period.dart';
import '../widgets/analysis_card.dart';
import '../widgets/category_details_section.dart';
import '../widgets/date_range_selector.dart';
import 'main_category_details_screen.dart';

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
  
  List<Expense> _realExpenses = [];
  List<Expense> _exceptionalExpenses = [];
  List<Expense> _totalExpenses = [];
  
  double _realTotal = 0;
  double _exceptionalTotal = 0;
  double _totalExpensesAmount = 0;
  
  double _realChange = 0;
  double _exceptionalChange = 0;
  double _totalChange = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _loadData() {
    final box = Hive.box<Expense>('expenses');
    final allExpenses = box.values.toList();

    final filteredExpenses = allExpenses.where((e) =>
      e.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
      e.date.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    _realExpenses = filteredExpenses.where((e) => !e.isExceptional).toList();
    _exceptionalExpenses = filteredExpenses.where((e) => e.isExceptional).toList();
    _totalExpenses = filteredExpenses;

    // حساب الإجماليات حسب الفئة الرئيسية
    _realTotal = _calculateTotalByMainCategory(_realExpenses);
    _exceptionalTotal = _calculateTotalByMainCategory(_exceptionalExpenses);
    _totalExpensesAmount = _realTotal + _exceptionalTotal;

    final periodDays = _getPeriodDays();
    final previousStart = _startDate.subtract(Duration(days: periodDays));
    final previousEnd = _endDate.subtract(Duration(days: periodDays));

    final previousExpenses = allExpenses.where((e) =>
      e.date.isAfter(previousStart.subtract(const Duration(days: 1))) &&
      e.date.isBefore(previousEnd.add(const Duration(days: 1)))
    ).toList();

    final previousReal = _calculateTotalByMainCategory(
      previousExpenses.where((e) => !e.isExceptional).toList()
    );
    final previousExceptional = _calculateTotalByMainCategory(
      previousExpenses.where((e) => e.isExceptional).toList()
    );
    final previousTotal = previousReal + previousExceptional;

    _realChange = previousReal == 0 ? 0 : ((_realTotal - previousReal) / previousReal) * 100;
    _exceptionalChange = previousExceptional == 0 ? 0 : ((_exceptionalTotal - previousExceptional) / previousExceptional) * 100;
    _totalChange = previousTotal == 0 ? 0 : ((_totalExpensesAmount - previousTotal) / previousTotal) * 100;

    setState(() {});
  }

  // دالة لحساب الإجمالي حسب الفئة الرئيسية
  double _calculateTotalByMainCategory(List<Expense> expenses) {
    double total = 0;
    final mainCategoriesMap = <String, double>{};
    
    for (final expense in expenses) {
      mainCategoriesMap[expense.mainCategoryId] = 
          (mainCategoriesMap[expense.mainCategoryId] ?? 0) + expense.amount;
    }
    
    for (final amount in mainCategoriesMap.values) {
      total += amount;
    }
    return total;
  }

  // دالة لتجميع المصروفات حسب الفئة الرئيسية
  Map<String, double> _groupByMainCategory(List<Expense> expenses) {
    final Map<String, double> result = {};
    
    for (final expense in expenses) {
      result[expense.mainCategoryId] = 
          (result[expense.mainCategoryId] ?? 0) + expense.amount;
    }
    return result;
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

  // دالة للحصول على اسم الفئة الرئيسية المترجم
  String _getMainCategoryName(String categoryId, BuildContext context) {
    final category = mainCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryConfig(id: categoryId, icon: ''),
    );
    return category.resolveTitle2(context);
  }

  @override
  Widget build(BuildContext context) {
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
  }

  Widget _buildTabContent({
    required String title,
    required double amount,
    required double change,
    required Color color,
    required List<Expense> expenses,
  }) {
    final mainCategoryData = _groupByMainCategory(expenses);
    
    // ✅ تحويل البيانات إلى الشكل المطلوب لـ MainCategoryData
    final List<MainCategoryData> categoryList = [];
    for (final entry in mainCategoryData.entries) {
      categoryList.add(MainCategoryData(
        id: entry.key,
        name: _getMainCategoryName(entry.key, context),
        total: entry.value,
      ));
    }
    
    // ✅ ترتيب تنازلي (من الأكبر للأصغر)
    categoryList.sort((a, b) => b.total.compareTo(a.total));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // كارت الملخص
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(amount),
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
                          ? "0% ${AppLocalizations.of(context)!.vsLastPeriod}"
                          : "${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}% ${AppLocalizations.of(context)!.vsLastPeriod}",
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
          ),
          const SizedBox(height: 24),
          // ✅ عرض الفئات الرئيسية فقط في الدائرة والقائمة (مع البيانات المرتبة)
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

  void _showMainCategoryDetails(String categoryId, String categoryName, List<Expense> allExpenses) {
    // تصفية المصروفات الخاصة بهذه الفئة الرئيسية فقط
    final filteredExpenses = allExpenses.where((e) => e.mainCategoryId == categoryId).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainCategoryDetailsScreen(
          mainCategoryId: categoryId,
          mainCategoryName: categoryName,
          expenses: filteredExpenses,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }
}
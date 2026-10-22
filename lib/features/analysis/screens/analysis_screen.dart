// lib/features/analysis/screens/analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/transaction.dart';
import '../../../services/transaction_query_service.dart';
import '../models/time_period.dart';
import '../controllers/analysis_controller.dart';
import '../widgets/analysis_summary_card.dart';
import '../widgets/category_section.dart';
import '../widgets/date_range_selector.dart';
import 'main_category_details_screen.dart';
import '../../../utils/currency_formatter.dart';
import '../widgets/custom_donut_chart.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnalysisController _controller;

  TimePeriod _selectedPeriod = TimePeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = AnalysisController(
      transactionQueryService: context.read<TransactionQueryService>(),
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );
    // ✅ _updateDateRange() removed from initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Load data only once after context is ready
    if (!_didLoad) {
      _didLoad = true;
      _updateDateRange();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
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

  Future<void> _loadData() async {
    late final DateTime previousStart;
    late final DateTime previousEnd;

    switch (_selectedPeriod) {
      case TimePeriod.daily:
        previousStart = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day - 1,
        );
        previousEnd = previousStart;
        break;
      case TimePeriod.weekly:
        previousStart = _startDate.subtract(const Duration(days: 7));
        previousEnd = _endDate.subtract(const Duration(days: 7));
        break;
      case TimePeriod.monthly:
        previousStart = DateTime(_startDate.year, _startDate.month - 1, 1);
        previousEnd = DateTime(_startDate.year, _startDate.month, 0);
        break;
      case TimePeriod.yearly:
        previousStart = DateTime(_startDate.year - 1, 1, 1);
        previousEnd = DateTime(_startDate.year, 1, 0);
        break;
      case TimePeriod.custom:
        final periodDays = _endDate.difference(_startDate).inDays + 1;
        previousStart = _startDate.subtract(Duration(days: periodDays));
        previousEnd = _endDate.subtract(Duration(days: periodDays));
        break;
    }

    await _controller.loadData(
      startDate: _startDate,
      endDate: _endDate,
      previousStartDate: previousStart,
      previousEndDate: previousEnd,
      t: AppLocalizations.of(context)!,
    );
  }

  void _onPeriodChanged(TimePeriod period) {
    _selectedPeriod = period;
    _updateDateRange();
  }

  void _onCurrencyChanged(String currencyCode) {
    _controller.selectCurrency(currencyCode);
    _loadData();
  }

  void _onDateRangeChanged(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    if (_selectedPeriod != TimePeriod.custom) {
      _selectedPeriod = TimePeriod.custom;
    }
    _loadData();
  }

  void _onCategoryTap(String categoryId, List<Transaction> expenses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainCategoryDetailsScreen(
          mainCategoryId: categoryId,
          expenses: expenses.where((e) => e.categoryId == categoryId).toList(),
          currencyCode: _controller.selectedCurrencyCode,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          t.analysis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            _controller.availableCurrencyCodes.length > 1 ? 132 : 100,
          ),
          child: Column(
            children: [
              DateRangeSelector(
                selectedPeriod: _selectedPeriod,
                startDate: _startDate,
                endDate: _endDate,
                onPeriodChanged: _onPeriodChanged,
                onDateRangeChanged: _onDateRangeChanged,
              ),
              if (_controller.availableCurrencyCodes.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Currency', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _controller.selectedCurrencyCode,
                          dropdownColor: const Color(0xFF20242C),
                          style: const TextStyle(color: Colors.white),
                          items: _controller.availableCurrencyCodes
                              .map((code) => DropdownMenuItem<String>(value: code, child: Text(code)))
                              .toList(),
                          onChanged: (code) {
                            if (code != null) _onCurrencyChanged(code);
                          },
                        ),
                      ),
                    ],
                  ),
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
                  tabs: [
                    Tab(text: t.total),
                    Tab(text: t.normal),
                    Tab(text: t.exceptional),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  title: t.total,
                  amount: _controller.totalAmount,
                  currencyCode: _controller.selectedCurrencyCode,
                  change: _controller.totalChange,
                  color: Colors.blue,
                  categories: _controller.totalByCategory,
                  donutData: _controller.totalDonutData,
                  expenses: _controller.totalExpenses,
                ),
                _buildTabContent(
                  title: t.normal,
                  amount: _controller.realAmount,
                  currencyCode: _controller.selectedCurrencyCode,
                  change: _controller.realChange,
                  color: Colors.green,
                  categories: _controller.realByCategory,
                  donutData: _controller.realDonutData,
                  expenses: _controller.realExpenses,
                ),
                _buildTabContent(
                  title: t.exceptional,
                  amount: _controller.exceptionalAmount,
                  currencyCode: _controller.selectedCurrencyCode,
                  change: _controller.exceptionalChange,
                  color: Colors.orange,
                  categories: _controller.exceptionalByCategory,
                  donutData: _controller.exceptionalDonutData,
                  expenses: _controller.exceptionalExpenses,
                ),
              ],
            ),
    );
  }

  Widget _buildTabContent({
    required String title,
    required double amount,
    required String currencyCode,
    required double? change,
    required Color color,
    required Map<String, double> categories,
    required List<DonutData> donutData,
    required List<Transaction> expenses,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AnalysisSummaryCard(
            title: title,
            formattedAmount: CurrencyFormatter.formatPrecise(amount, currencyCode),
            change: change,
            color: color,
          ),
          const SizedBox(height: 24),
          CategorySection(
            categories: categories,
            donutData: donutData,
            baseColor: color,
            currencyCode: currencyCode,
            onCategoryTap: (categoryId) => _onCategoryTap(categoryId, expenses),
          ),
        ],
      ),
    );
  }
}

// lib/features/analysis/screens/analysis_screen.dart

import 'package:flutter/material.dart';
import '../../../services/transaction_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/transaction.dart';
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

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _controller = AnalysisController(
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );

    final now = DateTime.now();

    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didLoad) {
      _didLoad = true;
      _loadData();
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
    final periodDays = _endDate.difference(_startDate).inDays + 1;
    final previousStart = _startDate.subtract(Duration(days: periodDays));
    final previousEnd = _endDate.subtract(Duration(days: periodDays));

    print('BEFORE LOAD');

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
                  change: _controller.totalChange,
                  color: Colors.blue,
                  categories: _controller.totalByCategory,
                  donutData: _controller.totalDonutData,
                  expenses: _controller.totalExpenses,
                ),
                _buildTabContent(
                  title: t.normal,
                  amount: _controller.realAmount,
                  change: _controller.realChange,
                  color: Colors.green,
                  categories: _controller.realByCategory,
                  donutData: _controller.realDonutData,
                  expenses: _controller.realExpenses,
                ),
                _buildTabContent(
                  title: t.exceptional,
                  amount: _controller.exceptionalAmount,
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
            formattedAmount: CurrencyFormatter.format(amount, 'EGP'),
            change: change,
            color: color,
          ),
          const SizedBox(height: 24),
          CategorySection(
            categories: categories,
            donutData: donutData,
            baseColor: color,
            onCategoryTap: (categoryId) => _onCategoryTap(categoryId, expenses),
          ),
        ],
      ),
    );
  }
}

// lib/features/analysis/screens/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/expense.dart';
import '../models/time_period.dart';
import '../widgets/analysis_card.dart';
import '../widgets/category_details_section.dart';
import '../widgets/date_range_selector.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  int _selectedCard = 0;
  bool _isCompareMode = false;
  int _compareCard1 = 0;
  int _compareCard2 = 1;
  Map<int, bool> _compareActive = {0: false, 1: false, 2: false};

  @override
  void initState() {
    super.initState();
    _updateDateRange();
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
    setState(() {});
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
    setState(() {});
  }

  void _onCardTap(int cardIndex) {
    if (_isCompareMode) {
      setState(() {
        if (_compareActive[cardIndex] == true) {
          _compareActive[cardIndex] = false;
        } else {
          _compareActive[cardIndex] = true;
        }
        final activeCards = _compareActive.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
        if (activeCards.length == 2) {
          _compareCard1 = activeCards[0];
          _compareCard2 = activeCards[1];
        }
      });
    } else {
      setState(() {
        _selectedCard = cardIndex;
      });
    }
  }

  void _toggleCompareMode() {
    setState(() {
      _isCompareMode = !_isCompareMode;
      if (!_isCompareMode) {
        _compareActive = {0: false, 1: false, 2: false};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Expense>('expenses');
    final allExpenses = box.values.toList();

    final filteredExpenses = allExpenses.where((e) =>
      e.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
      e.date.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    final realExpenses = filteredExpenses.where((e) => !e.isExceptional).toList();
    final exceptionalExpenses = filteredExpenses.where((e) => e.isExceptional).toList();

    final realTotal = realExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final exceptionalTotal = exceptionalExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalExpenses = realTotal + exceptionalTotal;

    final periodDays = _getPeriodDays();
    final previousStart = _startDate.subtract(Duration(days: periodDays));
    final previousEnd = _endDate.subtract(Duration(days: periodDays));

    final previousExpenses = allExpenses.where((e) =>
      e.date.isAfter(previousStart.subtract(const Duration(days: 1))) &&
      e.date.isBefore(previousEnd.add(const Duration(days: 1)))
    ).toList();

    final previousReal = previousExpenses.where((e) => !e.isExceptional).fold(0.0, (s, e) => s + e.amount);
    final previousExceptional = previousExpenses.where((e) => e.isExceptional).fold(0.0, (s, e) => s + e.amount);
    final previousTotal = previousReal + previousExceptional;

    final realChange = previousReal == 0 ? 0.0 : ((realTotal - previousReal) / previousReal) * 100;
    final exceptionalChange = previousExceptional == 0 ? 0.0 : ((exceptionalTotal - previousExceptional) / previousExceptional) * 100;
    final totalChange = previousTotal == 0 ? 0.0 : ((totalExpenses - previousTotal) / previousTotal) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text("Analysis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isCompareMode ? Icons.compare_arrows : Icons.compare, 
                color: _isCompareMode ? Colors.blue : Colors.white70),
            onPressed: _toggleCompareMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateRangeSelector(
              selectedPeriod: _selectedPeriod,
              startDate: _startDate,
              endDate: _endDate,
              onPeriodChanged: _onPeriodChanged,
              onDateRangeChanged: _onDateRangeChanged,
            ),
            const SizedBox(height: 24),
            
            if (!_isCompareMode)
              Row(
                children: [
                  _buildCard("Total Expenses", totalExpenses, totalChange, Colors.blue, 0),
                  const SizedBox(width: 8),
                  _buildCard("Real Expenses", realTotal, realChange, Colors.green, 1),
                  const SizedBox(width: 8),
                  _buildCard("Exceptional Expenses", exceptionalTotal, exceptionalChange, Colors.orange, 2),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AnalysisCard(
                      title: _getCardTitle(_compareCard1),
                      amount: _getCardAmount(_compareCard1, realTotal, exceptionalTotal, totalExpenses),
                      changePercentage: _getCardChange(_compareCard1, realChange, exceptionalChange, totalChange),
                      color: _getCardColor(_compareCard1),
                      isSelected: false,
                      onTap: () {},
                      isCompareActive: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnalysisCard(
                      title: _getCardTitle(_compareCard2),
                      amount: _getCardAmount(_compareCard2, realTotal, exceptionalTotal, totalExpenses),
                      changePercentage: _getCardChange(_compareCard2, realChange, exceptionalChange, totalChange),
                      color: _getCardColor(_compareCard2),
                      isSelected: false,
                      onTap: () {},
                      isCompareActive: false,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            if (!_isCompareMode)
              _buildDetailsSection(
                cardType: _selectedCard,
                realExpenses: realExpenses,
                exceptionalExpenses: exceptionalExpenses,
                totalExpenses: filteredExpenses,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CategoryDetailsSection(
                      title: _getCardTitle(_compareCard1),
                      expenses: _getCardExpenses(_compareCard1, realExpenses, exceptionalExpenses, filteredExpenses),
                      color: _getCardColor(_compareCard1),
                      isCompact: true,
                      onSubCategoryTap: (category) {
                        _showSubCategoryDetails(category);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CategoryDetailsSection(
                      title: _getCardTitle(_compareCard2),
                      expenses: _getCardExpenses(_compareCard2, realExpenses, exceptionalExpenses, filteredExpenses),
                      color: _getCardColor(_compareCard2),
                      isCompact: true,
                      onSubCategoryTap: (category) {
                        _showSubCategoryDetails(category);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, double amount, double change, Color color, int index) {
    return Expanded(
      child: AnalysisCard(
        title: title,
        amount: amount,
        changePercentage: change,
        color: color,
        isSelected: _selectedCard == index && !_isCompareMode,
        onTap: () => _onCardTap(index),
        isCompareActive: _compareActive[index] ?? false,
        onCompareTap: () {
          setState(() {
            _compareActive[index] = !(_compareActive[index] ?? false);
          });
        },
      ),
    );
  }

  Widget _buildDetailsSection({
    required int cardType,
    required List<Expense> realExpenses,
    required List<Expense> exceptionalExpenses,
    required List<Expense> totalExpenses,
  }) {
    switch (cardType) {
      case 0:
        return CategoryDetailsSection(
          title: "Total Expenses",
          expenses: totalExpenses,
          color: Colors.blue,
          onSubCategoryTap: _showSubCategoryDetails,
        );
      case 1:
        return CategoryDetailsSection(
          title: "Real Expenses",
          expenses: realExpenses,
          color: Colors.green,
          onSubCategoryTap: _showSubCategoryDetails,
        );
      case 2:
        return CategoryDetailsSection(
          title: "Exceptional Expenses",
          expenses: exceptionalExpenses,
          color: Colors.orange,
          onSubCategoryTap: _showSubCategoryDetails,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getCardTitle(int card) {
    switch (card) {
      case 0: return "Total Expenses";
      case 1: return "Real Expenses";
      case 2: return "Exceptional Expenses";
      default: return "";
    }
  }

  double _getCardAmount(int card, double real, double exceptional, double total) {
    switch (card) {
      case 0: return total;
      case 1: return real;
      case 2: return exceptional;
      default: return 0;
    }
  }

  double _getCardChange(int card, double realChange, double exceptionalChange, double totalChange) {
    switch (card) {
      case 0: return totalChange;
      case 1: return realChange;
      case 2: return exceptionalChange;
      default: return 0;
    }
  }

  Color _getCardColor(int card) {
    switch (card) {
      case 0: return Colors.blue;
      case 1: return Colors.green;
      case 2: return Colors.orange;
      default: return Colors.white;
    }
  }

  List<Expense> _getCardExpenses(int card, List<Expense> real, List<Expense> exceptional, List<Expense> total) {
    switch (card) {
      case 0: return total;
      case 1: return real;
      case 2: return exceptional;
      default: return [];
    }
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

  void _showSubCategoryDetails(String mainCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          appBar: AppBar(
            title: Text(mainCategory, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: Text(
              "Subcategory details for $mainCategory\nPeriod: ${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month} ${_endDate.year}",
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
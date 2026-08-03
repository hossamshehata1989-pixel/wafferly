// lib/features/analysis/widgets/date_range_selector.dart
import 'package:flutter/material.dart';
import '../models/time_period.dart';

class DateRangeSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final DateTime startDate;
  final DateTime endDate;
  final Function(TimePeriod) onPeriodChanged;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const DateRangeSelector({
    super.key,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
    required this.onPeriodChanged,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ✅ زر صغير على قدر المحتوى
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TimePeriod>(
              value: selectedPeriod,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white70,
                size: 20,
              ),
              items: [
                const DropdownMenuItem(
                  value: TimePeriod.daily,
                  child: Text("Daily"),
                ),
                const DropdownMenuItem(
                  value: TimePeriod.weekly,
                  child: Text("Weekly"),
                ),
                const DropdownMenuItem(
                  value: TimePeriod.monthly,
                  child: Text("Monthly"),
                ),
                const DropdownMenuItem(
                  value: TimePeriod.yearly,
                  child: Text("Yearly"),
                ),
                const DropdownMenuItem(
                  value: TimePeriod.custom,
                  child: Text("Custom Range"),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  if (value == TimePeriod.monthly) {
                    // اختيار شهر
                    _showMonthPicker(context);
                  } else if (value == TimePeriod.yearly) {
                    // اختيار سنة
                    _showYearPicker(context);
                  } else if (value == TimePeriod.weekly) {
                    // اختيار أسبوع من آخر 6 شهور
                    _showWeekPicker(context);
                  } else {
                    onPeriodChanged(value);
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ✅ زر التاريخ (يظهر فقط لـ daily, custom)
        if (selectedPeriod == TimePeriod.daily ||
            selectedPeriod == TimePeriod.custom)
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (selectedPeriod == TimePeriod.custom) {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                      start: startDate,
                      end: endDate,
                    ),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF3A7BFF),
                            surface: Color(0xFF1B2A6B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null)
                    onDateRangeChanged(picked.start, picked.end);
                } else if (selectedPeriod == TimePeriod.daily) {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF3A7BFF),
                            surface: Color(0xFF1B2A6B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onDateRangeChanged(picked, picked);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getDateRangeText(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2A6B),
          title: const Text(
            'Select Month',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final months = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec',
                ];
                return TextButton(
                  onPressed: () {
                    final newStart = DateTime(startDate.year, index + 1, 1);
                    final newEnd = DateTime(startDate.year, index + 1, 31);
                    onDateRangeChanged(newStart, newEnd);
                    Navigator.pop(context);
                  },
                  child: Text(
                    months[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showYearPicker(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - i);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2A6B),
          title: const Text(
            'Select Year',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    years[index].toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    final newStart = DateTime(years[index], 1, 1);
                    final newEnd = DateTime(years[index], 12, 31);
                    onDateRangeChanged(newStart, newEnd);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showWeekPicker(BuildContext context) {
    // آخر 6 شهور من الأسابيع
    final weeks = <DateTime>[];
    for (int i = 0; i < 24; i++) {
      final date = DateTime.now().subtract(Duration(days: i * 7));
      weeks.add(date);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2A6B),
          title: const Text(
            'Select Week',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                final weekStart = weeks[index];
                final weekEnd = weekStart.add(const Duration(days: 6));
                return ListTile(
                  title: Text(
                    "${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month} ${weekEnd.year}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    final newStart = DateTime(
                      weekStart.year,
                      weekStart.month,
                      weekStart.day,
                    );
                    final newEnd = DateTime(
                      weekEnd.year,
                      weekEnd.month,
                      weekEnd.day,
                    );
                    onDateRangeChanged(newStart, newEnd);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getDateRangeText() {
    if (selectedPeriod == TimePeriod.daily) {
      return "${startDate.day}/${startDate.month}/${startDate.year}";
    } else if (selectedPeriod == TimePeriod.weekly) {
      return "${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}";
    } else if (selectedPeriod == TimePeriod.monthly) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[startDate.month - 1]} ${startDate.year}";
    } else if (selectedPeriod == TimePeriod.yearly) {
      return "${startDate.year}";
    } else {
      return "${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month} ${endDate.year}";
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../theme/app_colors.dart';
import 'date_quick_card.dart';
import '../../widgets/bottom_sheet/sheet_header.dart';
import '../../widgets/bottom_sheet/sheet_footer.dart';

class DatePickerSheet extends StatefulWidget {
  final TransactionEntryController controller;

  const DatePickerSheet({super.key, required this.controller});

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.controller.selectedDate;
  }

  String _formatSubtitle(DateTime date) {
    final formatter = DateFormat('EEEE • MMM d');
    return formatter.format(date);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _confirmDate() {
    widget.controller.setSelectedDate(_selectedDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔹 الرأس المحسن مع أيقونة و subtitle
        SheetHeader(
          icon: Icons.calendar_today,
          title: 'Transaction Date',
          subtitle: 'Choose when this happened',
          onClose: () => Navigator.pop(context),
        ),

        const SizedBox(height: 20), // 🔹 مسافة بعد الهيدر
        // Quick Cards
        Row(
          children: [
            Expanded(
              child: DateQuickCard(
                icon: Icons.today,
                title: 'Today',
                subtitle: _formatSubtitle(now),
                onTap: () {
                  _selectDate(now);
                  _confirmDate();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateQuickCard(
                icon: Icons.history,
                title: 'Yesterday',
                subtitle: _formatSubtitle(yesterday),
                onTap: () {
                  _selectDate(yesterday);
                  _confirmDate();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20), // 🔹 مسافة بعد الكروت
        // Calendar (مع padding داخلي)
        Container(
          padding: const EdgeInsets.all(18), // 🔹 padding داخلي للتقويم
          decoration: BoxDecoration(
            color: AppColors.cardSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            onDateChanged: _selectDate,
            currentDate: DateTime.now(),
            selectableDayPredicate: (day) =>
                day.isBefore(DateTime.now()) ||
                day.isAtSameMomentAs(DateTime.now()),
          ),
        ),

        const SizedBox(height: 24), // 🔹 مسافة قبل الأزرار
        // Footer
        SheetFooter(
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.white.withOpacity(0.14)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _confirmDate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}

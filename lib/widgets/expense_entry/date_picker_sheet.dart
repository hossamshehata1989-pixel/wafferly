import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/transaction_entry_controller.dart';
import 'date_quick_card.dart';

class DatePickerSheet extends StatelessWidget {
  final TransactionEntryController controller;

  const DatePickerSheet({super.key, required this.controller});

  String _formatSubtitle(DateTime date) {
    final formatter = DateFormat('EEEE • MMM d'); // مثال: Monday • Jul 13
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Transaction Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            DateQuickCard(
              icon: Icons.today,
              title: 'Today',
              subtitle: _formatSubtitle(now),
              onTap: () {
                controller.setSelectedDate(now);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),

            DateQuickCard(
              icon: Icons.history,
              title: 'Yesterday',
              subtitle: _formatSubtitle(yesterday),
              onTap: () {
                controller.setSelectedDate(yesterday);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),

            // خيار "Pick another date" - يمكن استخدام نفس النمط أو زر منفصل
            DateQuickCard(
              icon: Icons.calendar_month,
              title: 'Pick another date',
              subtitle: 'Choose any date',
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate,
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
                  controller.setSelectedDate(picked);
                  Navigator.pop(context);
                }
              },
            ),

            const SizedBox(height: 12),

            // خيار Import old transactions (يمكن تركه أو تحويله أيضًا)
            DateQuickCard(
              icon: Icons.download,
              title: 'Import old transactions',
              subtitle: 'Recommended for importing historical data',
              onTap: () {
                // TODO: تنفيذ الاستيراد
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

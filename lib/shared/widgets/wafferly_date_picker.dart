import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/input/wafferly_input_decoration.dart';
import '../../theme/responsive_metrics.dart';

class WafferlyDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final String label;
  final ValueChanged<DateTime> onDateSelected;

  const WafferlyDatePicker({
    super.key,
    required this.selectedDate,
    required this.label,
    required this.onDateSelected,
  });

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale).format(date);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _pickDate(context),
      child: InputDecorator(
        isEmpty: selectedDate == null,
        decoration: WafferlyInputDecoration.build(
          context,
          label: label,
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: metrics.isCompactHeight ? 18 : 20,
            color: AppColors.textSecondary,
          ),
        ),
        child: Text(
          selectedDate == null
              ? 'Select date'
              : _formatDate(context, selectedDate!),
          style: TextStyle(
            fontSize: metrics.typography.body,
            color: selectedDate == null
                ? AppColors.textHint
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

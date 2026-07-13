// lib/shared/widgets/wafferly_date_picker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

class WafferlyDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final String label;
  final Function(DateTime) onDateSelected;

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
    return Card(
      child: InkWell(
        onTap: () => _pickDate(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.cake, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedDate == null
                      ? label
                      : _formatDate(context, selectedDate!),
                  style: TextStyle(
                    color: selectedDate == null
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

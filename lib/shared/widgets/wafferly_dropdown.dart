// lib/shared/widgets/wafferly_dropdown.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/input/wafferly_input_decoration.dart';

class WafferlyDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final String? hint;
  final FormFieldValidator<T>? validator;
  final Function(T?) onChanged;

  const WafferlyDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    this.hint,
    this.validator,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      hint: hint == null
          ? null
          : Text(hint!, style: const TextStyle(color: AppColors.textSecondary)),
      validator: validator,
      decoration: WafferlyInputDecoration.build(context, label: label),
      dropdownColor: AppColors.card,
      style: const TextStyle(color: AppColors.textPrimary),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
    );
  }
}

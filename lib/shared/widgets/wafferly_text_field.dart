// lib/shared/widgets/wafferly_text_field.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WafferlyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? minLines;
  final int? maxLines;
  final bool obscureText;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;

  const WafferlyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.minLines,
    this.maxLines = 1,
    this.obscureText = false,
    this.validator,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines != null && maxLines! > 1;

    return TextFormField(
      controller: controller,

      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),

      textDirection: Directionality.of(context),

      keyboardType: isMultiline ? TextInputType.multiline : keyboardType,

      textInputAction: isMultiline ? TextInputAction.newline : textInputAction,

      minLines: minLines,

      maxLines: maxLines,

      obscureText: obscureText,

      validator: validator,

      autofillHints: autofillHints,

      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

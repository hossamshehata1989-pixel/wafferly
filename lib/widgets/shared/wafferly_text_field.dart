// lib/widgets/shared/wafferly_text_field.dart

import 'package:flutter/material.dart';
import 'package:wafferly/theme/responsive_metrics.dart';

class WafferlyTextField extends StatelessWidget {
  final TextEditingController controller;
  final int? minLines;
  final List<String>? autofillHints;

  final String label;
  final String? hint;
  final String? prefixText;

  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;

  final String? Function(String?)? validator;

  const WafferlyTextField({
    super.key,
    required this.controller,
    required this.label,

    this.hint,
    this.prefixText,

    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,

    this.validator,

    this.minLines,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: maxLines != null && maxLines! > 1
          ? TextInputType.multiline
          : keyboardType,

      textInputAction: maxLines != null && maxLines! > 1
          ? TextInputAction.newline
          : textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      autofillHints: autofillHints,
      validator: validator,

      style: TextStyle(color: Colors.white, fontSize: metrics.typography.body),

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,

        labelStyle: TextStyle(
          color: Colors.white54,
          fontSize: metrics.typography.body,
        ),

        hintStyle: TextStyle(
          color: Colors.white38,
          fontSize: metrics.typography.body,
        ),

        prefixStyle: TextStyle(
          color: Colors.white54,
          fontSize: metrics.typography.body,
        ),

        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),

        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}

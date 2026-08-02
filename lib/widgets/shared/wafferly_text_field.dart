import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/input/wafferly_input_decoration.dart';
import '../../theme/responsive_metrics.dart';

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

  final List<TextInputFormatter>? inputFormatters;

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
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    final isMultiline = maxLines > 1;

    return TextFormField(
      controller: controller,

      keyboardType: isMultiline ? TextInputType.multiline : keyboardType,

      textInputAction: isMultiline ? TextInputAction.newline : textInputAction,

      maxLines: maxLines,
      minLines: minLines,

      autofillHints: autofillHints,

      validator: validator,

      inputFormatters: inputFormatters,

      style: TextStyle(color: Colors.white, fontSize: metrics.typography.body),

      decoration: WafferlyInputDecoration.build(
        context,
        label: label,
        hint: hint,
        prefixText: prefixText,
      ),
    );
  }
}

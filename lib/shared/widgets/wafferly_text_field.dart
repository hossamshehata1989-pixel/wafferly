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
  final int? maxLength;

  final String? Function(String?)? validator;
  final bool readOnly;

  final List<TextInputFormatter>? inputFormatters;
  final double spacingAfter;

  const WafferlyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1, 
    this.maxLength,
    this.validator,
    this.readOnly = false,
    this.minLines,
    this.autofillHints,
    this.inputFormatters,
    this.spacingAfter = 0,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    final isMultiline = maxLines > 1;

    return Padding(
      padding: EdgeInsets.only(bottom: spacingAfter),
      child: TextFormField(
      controller: controller,
      readOnly: readOnly,

      keyboardType: isMultiline ? TextInputType.multiline : keyboardType,

      textInputAction: isMultiline ? TextInputAction.newline : textInputAction,

      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,

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
      ),
    );
  }
}

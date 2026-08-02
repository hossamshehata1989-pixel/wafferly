import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../responsive_metrics.dart';

class WafferlyInputDecoration {
  const WafferlyInputDecoration._();

  static InputDecoration build(
    BuildContext context, {
    required String label,

    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    final metrics = ResponsiveMetrics.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixText: prefixText,

      floatingLabelBehavior: FloatingLabelBehavior.always,

      isDense: metrics.isCompactHeight,

      contentPadding: EdgeInsets.symmetric(
        horizontal: metrics.space.md,
        vertical: metrics.input.verticalPadding,
      ),

      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: metrics.typography.body,
      ),

      hintStyle: TextStyle(
        color: AppColors.textHint,
        fontSize: metrics.typography.body,
      ),

      prefixStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: metrics.typography.body,
      ),
    );
  }
}

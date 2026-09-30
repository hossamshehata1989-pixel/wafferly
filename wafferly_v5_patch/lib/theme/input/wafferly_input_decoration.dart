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
      filled: true,
      fillColor: AppColors.card,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(14),
        vertical: metrics.isCompactHeight ? 7 : 9,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(metrics.size(12)),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(metrics.size(12)),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(metrics.size(12)),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(metrics.size(12)),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
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

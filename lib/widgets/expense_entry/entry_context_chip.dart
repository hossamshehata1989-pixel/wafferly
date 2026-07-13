// lib/widgets/expense_entry/entry_context_chip.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';

class EntryContextChip extends StatelessWidget {
  final ResponsiveMetrics metrics;

  final IconData? icon;
  final Color? iconColor;

  final String label;

  final Widget? trailing;

  final VoidCallback? onTap;

  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const EntryContextChip({
    super.key,
    required this.metrics,
    this.icon,
    this.iconColor,
    required this.label,
    this.trailing,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final height = metrics.width < 360 ? metrics.h(38) : metrics.h(45);
    final effectiveBackgroundColor =
        backgroundColor ?? AppColors.calculatorButton;
    final effectiveIconColor = iconColor ?? Colors.white70;
    final effectiveBorderColor =
        borderColor ?? effectiveIconColor.withValues(alpha: .20);
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 10);

    // ✅ استخراج BorderRadius
    final borderRadius = BorderRadius.circular(10);

    // ✅ استخراج TextStyle
    final labelStyle = TextStyle(
      fontSize: metrics.text(12),
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: .90),
    );

    // الحالة الأولى: لا يوجد أيقونة ولا عنصر تابع → نص فقط في المنتصف
    if (icon == null && trailing == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: Colors.white.withValues(alpha: .08),
        highlightColor: Colors.white.withValues(alpha: .04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: height,
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: borderRadius,
            border: Border.all(color: effectiveBorderColor),
          ),
          alignment: Alignment.center,
          padding: effectivePadding,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      );
    }

    // الحالة الثانية: أيقونة و/أو عنصر تابع → تخطيط Row
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      splashColor: effectiveIconColor.withValues(alpha: .15),
      highlightColor: effectiveIconColor.withValues(alpha: .08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: height,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: borderRadius,
          border: Border.all(color: effectiveBorderColor),
        ),
        padding: effectivePadding,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon!, color: effectiveIconColor, size: metrics.size(17)),
              SizedBox(width: metrics.spacing(6)),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

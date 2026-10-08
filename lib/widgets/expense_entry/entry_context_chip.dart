// lib/widgets/expense_entry/entry_context_chip.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';

class EntryContextChip extends StatelessWidget {
  final ResponsiveMetrics metrics;

  final Widget? leading;
  final Color? iconColor;

  final String label;
  final String? subtitle;

  final Widget? trailing;

  final VoidCallback? onTap;

  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const EntryContextChip({
    super.key,
    required this.metrics,
    this.leading,
    this.iconColor,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.padding,
  });

  Widget _textContent(
    TextStyle labelStyle,
    TextStyle subtitleStyle, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    // scaleDown: when the chip is narrow the text gets smaller instead of
    // being cut to "…" or disappearing completely.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: hasSubtitle
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, style: labelStyle),
                const SizedBox(height: 1),
                Text(subtitle!, maxLines: 1, style: subtitleStyle),
              ],
            )
          : Text(label, maxLines: 1, style: labelStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Match EntryBottomActions exactly: one shared row height per device.
    final isCompactDevice = metrics.width < 360 || metrics.isCompactHeight;
    final height = isCompactDevice ? metrics.h(42) : metrics.h(48);
    final effectiveBackgroundColor =
        backgroundColor ?? AppColors.calculatorButton;
    final effectiveIconColor = iconColor ?? Colors.white70;
    final effectiveBorderColor =
        borderColor ?? effectiveIconColor.withValues(alpha: .20);
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 8);

    final borderRadius = BorderRadius.circular(10);
    final labelStyle = TextStyle(
      fontSize: metrics.text(12),
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: .90),
      height: 1.0,
    );
    final subtitleStyle = TextStyle(
      fontSize: metrics.text(10),
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: .62),
      height: 1.0,
    );

    if (leading == null && trailing == null) {
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
          child: _textContent(
            labelStyle,
            subtitleStyle,
            alignment: Alignment.center,
          ),
        ),
      );
    }

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
            if (leading != null) ...[
              leading!,
              SizedBox(width: metrics.spacing(5)),
            ],
            Expanded(
              child: _textContent(labelStyle, subtitleStyle),
            ),
            if (trailing != null) ...[
              SizedBox(width: metrics.spacing(4)),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// lib/shared/widgets/wafferly_button.dart

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/responsive_metrics.dart';

class WafferlyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final bool loading;
  final bool fullWidth;
  final double? widthFactor;
  final Color? backgroundColor;
  final IconData? icon;

  const WafferlyButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.loading = false,
    this.fullWidth = true,
    this.widthFactor,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(0, metrics.isCompactHeight ? 48 : 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.radius.lg),
        ),
        textStyle: TextStyle(
          fontSize: metrics.typography.title,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: loading
          ? SizedBox(
              width: metrics.icon.small,
              height: metrics.icon.small,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: metrics.icon.small),
                  SizedBox(width: metrics.space.sm),
                ],
                Text(title),
              ],
            ),
    );

    if (fullWidth) {
      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: widthFactor == null
              ? double.infinity
              : metrics.width * widthFactor!,
          height: metrics.isCompactHeight ? 40 : 52,
          child: button,
        ),
      );
    }

    return button;
  }
}

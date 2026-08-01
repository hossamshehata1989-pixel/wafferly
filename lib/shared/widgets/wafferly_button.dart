// lib/shared/widgets/wafferly_button.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:wafferly/theme/responsive_metrics.dart';

class WafferlyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final bool loading;
  final bool fullWidth;
  final Color? backgroundColor;
  final IconData? icon;

  const WafferlyButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.loading = false,
    this.fullWidth = true,
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
        minimumSize: fullWidth
            ? Size(double.infinity, metrics.button.height)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(title),
              ],
            ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: metrics.button.height,
        child: button,
      );
    }

    return button;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import '../expense_entry/amount_input_panel.dart';
import '../../theme/responsive_metrics.dart';

class WafferlyToast {
  static OverlayEntry? _currentToast;

  static void show({
    required BuildContext context,
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double? top,
    double? bottom,
  }) {
    _currentToast?.remove();

    final overlay = Overlay.of(context);

    double? resolvedTop = top;

    if (resolvedTop == null && bottom == null) {
      final panelContext = AmountInputPanel.panelKey.currentContext;

      if (panelContext != null) {
        final box = panelContext.findRenderObject() as RenderBox;

        final offset = box.localToGlobal(Offset.zero);

        const toastHeight = 56.0;

        resolvedTop = offset.dy - toastHeight - 8;
      }
    }

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        top: resolvedTop,
        bottom: bottom,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 220),
            tween: Tween(begin: 20, end: 0),
            builder: (context, value, widget) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Opacity(opacity: 1 - value / 20, child: widget),
              );
            },
            child: child,
          ),
        ),
      ),
    );

    _currentToast = entry;

    overlay.insert(entry);

    Timer(duration, () {
      if (_currentToast == entry) {
        entry.remove();
        _currentToast = null;
      }
    });
  }

  static void showError(BuildContext context, {required String message}) {
    show(
      context: context,
      child: _ToastCard(
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFE85D5D),
        message: message,
      ),
    );
  }

  static void showSuccess(BuildContext context, {required String message}) {
    show(
      context: context,
      bottom: 32,
      duration: const Duration(milliseconds: 1000),
      child: _ToastCard(
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF2DBE74),
        message: message,
      ),
    );
  }

  static void showWarning(BuildContext context, {required String message}) {
    show(
      context: context,
      child: _ToastCard(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF5A623),
        message: message,
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _ToastCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isCompact = metrics.width < 360 || metrics.height < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isCompact ? 18 : 22),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

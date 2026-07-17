import 'dart:async';

import 'package:flutter/material.dart';

class WafferlyToast {
  static OverlayEntry? _currentToast;

  static void show({
    required BuildContext context,
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double bottom = 140,
  }) {
    _currentToast?.remove();

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

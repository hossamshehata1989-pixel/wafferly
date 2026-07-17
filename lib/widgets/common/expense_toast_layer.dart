import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/toast_service.dart';
import '../../theme/responsive_metrics.dart';
import '../expense_entry/amount_input_panel.dart';

class ExpenseToastLayer extends StatefulWidget {
  const ExpenseToastLayer({super.key});

  @override
  State<ExpenseToastLayer> createState() => _ExpenseToastLayerState();
}

class _ExpenseToastLayerState extends State<ExpenseToastLayer> {
  Timer? _timer;
  ToastData? _lastToast;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ToastData?>(
      valueListenable: ToastService.toast,
      builder: (context, toast, _) {
        if (toast != null && toast != _lastToast) {
          _lastToast = toast;

          _timer?.cancel();
          _timer = Timer(toast.duration, () {
            ToastService.hide();
          });
        }

        if (toast == null) {
          return const SizedBox.shrink();
        }

        double? top;
        double? bottom;

        switch (toast.type) {
          case ToastType.success:
            top = 0;
            break;

          case ToastType.error:
          case ToastType.warning:
            final panelContext = AmountInputPanel.panelKey.currentContext;

            if (panelContext != null) {
              final box = panelContext.findRenderObject() as RenderBox;

              bottom = box.size.height + 8;
            } else {
              bottom = 180;
            }
            break;
        }

        return Positioned(
          left: 16,
          right: 16,
          top: top,
          bottom: bottom,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 220),
            tween: Tween(begin: 20.0, end: 0.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Opacity(opacity: 1 - value / 20, child: child),
              );
            },
            child: _ToastCard(toast: toast),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _SuccessBanner extends StatefulWidget {
  const _SuccessBanner();

  @override
  State<_SuccessBanner> createState() => _SuccessBannerState();
}

class _SuccessBannerState extends State<_SuccessBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        setState(() => _visible = true);
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final toast = ToastService.toast.value!;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      offset: _visible ? Offset.zero : const Offset(0, -1),

      child: Align(
        alignment: Alignment.topCenter,

        child: Material(
          color: const Color.fromARGB(238, 255, 1, 1),

          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 14,
              left: 18,
              right: 18,
            ),
            color: const Color(0xFF2DBE74),

            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    toast.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  final ToastData toast;

  const _ToastCard({required this.toast});

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isCompact = metrics.width < 360 || metrics.height < 700;

    late final IconData icon;
    late final Color color;

    switch (toast.type) {
      case ToastType.success:
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFF2DBE74);
        break;

      case ToastType.error:
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFE85D5D);
        break;

      case ToastType.warning:
        icon = Icons.warning_amber_rounded;
        color = const Color(0xFFF5A623);
        break;
    }

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
              toast.message,
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

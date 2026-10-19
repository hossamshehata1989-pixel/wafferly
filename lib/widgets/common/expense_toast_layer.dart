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
        if (toast != null &&
            toast != _lastToast &&
            toast.type != ToastType.success) {
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

        if (toast.type == ToastType.success) {
          // key: a second success while the first is on screen restarts the
          // banner instead of inheriting the first one's timers.
          return _SuccessBanner(key: ValueKey(toast), toast: toast);
        }

        return Positioned(
          left: 16,
          right: 16,
          top: top,
          bottom: bottom,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300), // Error
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
}

class _SuccessBanner extends StatefulWidget {
  final ToastData toast;

  const _SuccessBanner({super.key, required this.toast});

  @override
  State<_SuccessBanner> createState() => _SuccessBannerState();
}

class _SuccessBannerState extends State<_SuccessBanner> {
  static const _slide = Duration(milliseconds: 280);
  static const _visibleFor = Duration(milliseconds: 1800);
  static const _green = Color(0xFF2DBE74);

  bool _visible = false;
  Timer? _hideTimer;
  Timer? _removeTimer;

  @override
  void initState() {
    super.initState();

    // Start off-screen, then slide in on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });

    _hideTimer = Timer(_visibleFor, () {
      if (!mounted) return;
      setState(() => _visible = false);

      // Remove the toast only after the slide-out has finished.
      _removeTimer = Timer(_slide, () {
        if (ToastService.toast.value == widget.toast) {
          ToastService.hide();
        }
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AnimatedSlide(
            duration: _slide,
            curve: _visible ? Curves.easeOutCubic : Curves.easeInCubic,
            offset: _visible ? Offset.zero : const Offset(0, -1.6),
            child: AnimatedOpacity(
              duration: _slide,
              opacity: _visible ? 1 : 0,
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10261F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _green.withValues(alpha: .55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: .18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: _green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.toast.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
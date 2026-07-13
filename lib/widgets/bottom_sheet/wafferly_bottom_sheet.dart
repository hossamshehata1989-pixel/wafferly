// lib/widgets/bottom_sheet/wafferly_bottom_sheet.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'sheet_background.dart';
import 'sheet_drag_handle.dart';
import 'sheet_body.dart';

class WafferlyBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Color barrierColor = const Color(0x80000000),
    bool barrierDismissible = true,
    String? barrierLabel,
    bool useSafeArea = true,
    double radius = 28, // 🔹 تم رفعها إلى 28
    bool showDragHandle = true,
    Duration transitionDuration = const Duration(milliseconds: 350),
    Curve transitionCurve = Curves.easeOut,
    bool enableGlass = false,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.all(16),
    bool scrollable = false,
    double maxWidth = 600,
  }) {
    final effectiveBarrierLabel =
        barrierLabel ?? (barrierDismissible ? 'Dismiss' : null);

    return showGeneralDialog<T>(
      context: context,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: effectiveBarrierLabel,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // خلفية التطبيق
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: enableGlass ? 18 : 0,
                  sigmaY: enableGlass ? 18 : 0,
                ),
                child: Container(
                  color: Colors.black.withOpacity(enableGlass ? 0.18 : 0.0),
                ),
              ),

              // الشيت نفسه مع Fade + Slide
              Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: transitionCurve,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: transitionCurve,
                          ),
                        ),
                    child: SheetBackground(
                      radius: radius,
                      enableGlass: enableGlass,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16, // 🔹 تم تعديل الهوامش
                          vertical: 8,
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDragHandle) ...[
                                const SizedBox(height: 8),
                                const SheetDragHandle(),
                                const SizedBox(height: 4),
                              ],
                              Flexible(
                                fit: FlexFit.loose,
                                child: SheetBody(
                                  padding: bodyPadding,
                                  scrollable: scrollable,
                                  maxWidth: maxWidth,
                                  child: child,
                                ),
                              ),
                              if (useSafeArea) const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

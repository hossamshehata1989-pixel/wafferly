// lib/widgets/bottom_sheet/sheet_background.dart
import 'bottom_sheet_theme.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

class SheetBackground extends StatelessWidget {
  final Widget child;
  final double radius;
  final BottomSheetTheme theme;
  const SheetBackground({
    super.key,
    required this.child,
    this.radius = 24,
    this.theme = BottomSheetTheme.solid,
  });

  @override
  Widget build(BuildContext context) {
    final isGlass = theme == BottomSheetTheme.glass;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isGlass ? 18 : 0,
          sigmaY: isGlass ? 18 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isGlass
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFF1F2432),

            gradient: isGlass
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      const Color(0xFF1F2432).withOpacity(0.82),
                    ],
                  )
                : null,

            borderRadius: BorderRadius.circular(radius),

            border: isGlass
                ? Border.all(color: Colors.white.withOpacity(0.12), width: 1)
                : null,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isGlass ? 0.45 : 0.25),
                blurRadius: isGlass ? 40 : 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

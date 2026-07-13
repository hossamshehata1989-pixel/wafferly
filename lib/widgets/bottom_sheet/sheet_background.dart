// lib/widgets/bottom_sheet/sheet_background.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class SheetBackground extends StatelessWidget {
  final Widget child;
  final double radius;
  final bool enableGlass;

  const SheetBackground({
    super.key,
    required this.child,
    this.radius = 24,
    this.enableGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: enableGlass ? 18 : 0,
          sigmaY: enableGlass ? 18 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: enableGlass ? null : const Color(0xFF1F2432),
            gradient: enableGlass
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      const Color(0xFF1F2432).withOpacity(0.82),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(radius),
            border: enableGlass
                ? Border.all(color: Colors.white.withOpacity(0.08))
                : null,
            boxShadow: enableGlass
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

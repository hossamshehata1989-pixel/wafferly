// lib/widgets/bottom_sheet/sheet_drag_handle.dart

import 'package:flutter/material.dart';

class SheetDragHandle extends StatelessWidget {
  final Color? color;
  final double width;
  final double height;

  const SheetDragHandle({
    super.key,
    this.color,
    this.width = 48,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// lib/widgets/bottom_sheet/sheet_body.dart

import 'package:flutter/material.dart';

class SheetBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final double maxWidth;

  const SheetBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.scrollable = false,
    this.maxWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      child: child,
    );

    if (scrollable) {
      return SingleChildScrollView(child: content);
    }

    return content;
  }
}

// lib/widgets/bottom_sheet/sheet_footer.dart

import 'package:flutter/material.dart';

class SheetFooter extends StatelessWidget {
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const SheetFooter({
    super.key,
    required this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions.map((child) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: child,
            ),
          );
        }).toList(),
      ),
    );
  }
}

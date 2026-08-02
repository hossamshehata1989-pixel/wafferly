import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/responsive_metrics.dart';

class AccountIconPicker extends StatelessWidget {
  const AccountIconPicker({
    super.key,
    required this.icons,
    required this.selectedIcon,
    required this.onChanged,
  });

  final List<String> icons;
  final String? selectedIcon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);

    final iconSize = metrics.icon.accountPicker;

    return Align(
      alignment: Directionality.of(context) == TextDirection.rtl
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Wrap(
        spacing: metrics.space.sm,
        runSpacing: metrics.space.sm,
        children: icons.map((icon) {
          return _IconTile(
            icon: icon,
            selected: icon == selectedIcon,
            iconSize: iconSize,
            onTap: () => onChanged(icon),
          );
        }).toList(),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.selected,
    required this.iconSize,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          // حجم الدائرة = حجم الأيقونة + Padding
          width: iconSize + 16,
          height: iconSize + 16,

          padding: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? primary.withValues(alpha: .12)
                : Colors.white.withValues(alpha: .04),
            border: Border.all(
              color: selected ? primary : Colors.white24,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: .30),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),

          child: Center(
            child: SvgPicture.asset(
              icon,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

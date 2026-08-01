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
    const double gridSpacing = 12.0;
    const double tileRadius = 14.0;
    const double padding = 12.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
      ),
      itemBuilder: (_, index) {
        final icon = icons[index];
        final selected = icon == selectedIcon;

        return InkWell(
          onTap: () => onChanged(icon),
          borderRadius: BorderRadius.circular(tileRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(tileRadius),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white24,
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: SvgPicture.asset(icon, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }
}

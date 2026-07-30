import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) {
        final icon = icons[index];
        final selected = icon == selectedIcon;

        return InkWell(
          onTap: () => onChanged(icon),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white24,
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(icon, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }
}

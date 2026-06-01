import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

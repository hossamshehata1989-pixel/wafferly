import 'package:flutter/material.dart';
import 'entry_mode.dart';

class EntryModeConfig {
  final IconData accountIcon;
  final String submitButtonTitle;
  final bool showExceptional;

  const EntryModeConfig({
    required this.accountIcon,
    required this.submitButtonTitle,
    required this.showExceptional,
  });

  factory EntryModeConfig.of(EntryMode mode) {
    switch (mode) {
      case EntryMode.expense:
        return const EntryModeConfig(
          accountIcon: Icons.arrow_outward,
          submitButtonTitle: 'Add',
          showExceptional: true,
        );

      case EntryMode.income:
        return const EntryModeConfig(
          accountIcon: Icons.arrow_downward,
          submitButtonTitle: 'Add Income',
          showExceptional: false,
        );

      case EntryMode.transfer:
        return const EntryModeConfig(
          accountIcon: Icons.swap_horiz,
          submitButtonTitle: 'Transfer',
          showExceptional: false,
        );
    }
  }
}

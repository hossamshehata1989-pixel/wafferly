// lib/shared/widgets/wafferly_section_title.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WafferlySectionTitle extends StatelessWidget {
  final String title;

  const WafferlySectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

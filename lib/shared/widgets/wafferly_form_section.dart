// lib/shared/widgets/wafferly_form_section.dart

import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import 'wafferly_section_title.dart';

class WafferlyFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showSpacing;

  const WafferlyFormSection({
    super.key,
    required this.title,
    required this.children,
    this.showSpacing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WafferlySectionTitle(title: title),
        const SizedBox(height: AppSpacing.sm),
        ...children,
        if (showSpacing) const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

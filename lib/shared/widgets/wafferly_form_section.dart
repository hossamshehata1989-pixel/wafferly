// lib/shared/widgets/wafferly_form_section.dart

import 'package:flutter/material.dart';
import 'wafferly_section_title.dart';
import 'package:wafferly/theme/responsive_metrics.dart';

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
    final metrics = ResponsiveMetrics.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WafferlySectionTitle(title: title),
        SizedBox(height: metrics.space.sm), // original spacing after title
        ...children,
        if (showSpacing)
          SizedBox(
            height: metrics.space.lg,
          ), // original spacing between sections
      ],
    );
  }
}

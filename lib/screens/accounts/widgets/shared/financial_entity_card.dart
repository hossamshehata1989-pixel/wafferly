import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../theme/responsive_metrics.dart';
import '../../../../theme/financial_entity_visual.dart';

/// Generic card surface with decorative background SVG, ripple effect,
/// and fully theme‑driven styling.
///
/// - All colors are derived from the current Theme.
/// - Background SVG is positioned responsively using LayoutBuilder.
/// - Radius, padding, shadow, border, and opacity are fixed design‑system values.
/// - Does NOT contain any business logic or domain‑specific content.
class FinancialEntityCard extends StatelessWidget {
  const FinancialEntityCard({
    super.key,
    required this.visual,
    required this.child,
    this.onTap,
  });

  final FinancialEntityVisual visual;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = ResponsiveMetrics.of(context);

    // Design‑system constants (not customizable per widget)
    const double kBorderRadius = 14.0;
    const double kBackgroundOpacity = 0.06;
    const double kSvgColorOpacity = 0.7;
    const double kSvgSize = 60.0;

    // Decorative SVG horizontal offset as a fraction of card width.

    const double kRightFraction = 0.2; // 20% from right edge

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.spacing(12),
        vertical: metrics.spacing(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rightOffset = constraints.maxWidth * kRightFraction;

          return Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(metrics.size(kBorderRadius)),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.25),
                  blurRadius: metrics.size(8),
                  offset: Offset(0, metrics.size(3)),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Responsive decorative background SVG
                Positioned(
                  right: rightOffset,
                  top: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: kBackgroundOpacity,
                      child: SvgPicture.asset(
                        visual.backgroundSvg,
                        width: metrics.size(kSvgSize),
                        height: metrics.size(kSvgSize),
                        colorFilter: ColorFilter.mode(
                          visual.surfaceAccent.withOpacity(kSvgColorOpacity),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                // Main content with ripple
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    metrics.size(kBorderRadius),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      metrics.size(kBorderRadius),
                    ),
                    onTap: onTap,
                    child: Padding(
                      padding: EdgeInsets.all(metrics.spacing(14)),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// lib/widgets/expense_entry/entry_bottom_actions.dart

import 'package:flutter/material.dart';
import '../../../controllers/transaction_entry_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/responsive_metrics.dart';
import '../../../features/transactions/models/entry_mode.dart';
import '../../../features/transactions/models/entry_mode_extension.dart';
import '../../notifications/wafferly_toast.dart';
import '../entry_done_handler.dart';

class EntryBottomActions extends StatelessWidget {
  final TransactionEntryController controller;
  final ResponsiveMetrics metrics;
  final EntryMode mode;

  const EntryBottomActions({
    super.key,
    required this.controller,
    required this.metrics,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == EntryMode.expense) {
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _buildExpenseBottomRow(context),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _bottomActionButton(
            metrics,
            '',
            Icons.more_horiz,
          ),
        ),
        SizedBox(width: metrics.spacing(6)),
        Expanded(
          flex: 2,
          child: _buildPrimaryAction(context, metrics),
        ),
        SizedBox(width: metrics.spacing(6)),
        Expanded(
          child: _bottomActionButton(
            metrics,
            '',
            Icons.mic,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseBottomRow(BuildContext context) {
    final isSmallScreen = metrics.width < 360;
    final height = isSmallScreen ? metrics.h(42) : metrics.h(48);

    final micSize = isSmallScreen ? metrics.size(32) : metrics.size(36);
    // Done and Add sit almost edge to edge; the mic floats on the seam and
    // both buttons are cut by a circle slightly bigger than the mic, so the
    // halo around it has the same width everywhere.
    const seam = 4.0;
    const haloWidth = 4.0;
    final cutoutRadius = micSize / 2 + haloWidth;
    final canAdd = controller.hasCategory && controller.hasAmount;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: _compactActionButton(
              height: height,
              icon: Icons.document_scanner_outlined,
              label: 'Scan',
              subtitle: 'Import',
              onTap: () {},
            ),
          ),
          SizedBox(width: metrics.spacing(4)),
          Expanded(
            flex: 30,
            child: SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: _NotchedActionButton(
                            height: height,
                            side: _NotchedSide.right,
                            cutoutRadius: cutoutRadius,
                            seam: seam,
                            backgroundColor: const Color(0xFFA7F3D0),
                            foregroundColor: const Color(0xFF065F46),
                            icon: Icons.check_rounded,
                            label: 'Done',
                            onTap: () => handleEntryDone(context, controller),
                          ),
                        ),
                        const SizedBox(width: seam),
                        Expanded(
                          child: _NotchedAddButton(
                            height: height,
                            cutoutRadius: cutoutRadius,
                            seam: seam,
                            isExceptional: controller.isExceptional,
                            enabled: canAdd,
                            onAddTap: () => canAdd
                                ? _submitEntry(context)
                                : WafferlyToast.showError(
                                    context,
                                    message:
                                        'Choose a category and enter an amount first',
                                  ),
                            onStarTap: controller.toggleExceptional,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _MicButton(
                      size: micSize,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: metrics.spacing(4)),
          Expanded(
            flex: 9,
            child: _compactActionButton(
              height: height,
              icon: Icons.note_alt_outlined,
              label: 'Note',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactActionButton({
    required double height,
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.cardSecondary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: subtitle == null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white70, size: 17),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white70, size: 15),
                        const SizedBox(height: 1),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context, ResponsiveMetrics metrics) {
    switch (mode) {
      case EntryMode.expense:
        return _buildLegacyExpenseAction(context, metrics);
      case EntryMode.income:
        return _buildIncomeAction(context, metrics);
      case EntryMode.transfer:
        return _buildExpenseAction(context, metrics);
    }
  }

  Widget _buildExpenseAction(
    BuildContext context,
    ResponsiveMetrics metrics,
  ) {
    final config = mode.config;
    final double height =
        metrics.width < 360 ? metrics.h(38) : metrics.h(45);

    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: InkWell(
                onTap: controller.toggleExceptional,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: controller.isExceptional
                        ? Colors.amber.withOpacity(0.35)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Exceptional',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.help_outline,
                        size: 13,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                onTap: () => _submitEntry(context),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        config.submitButtonTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyExpenseAction(
    BuildContext context,
    ResponsiveMetrics metrics,
  ) {
    final config = mode.config;
    final double height =
        metrics.width < 360 ? metrics.h(38) : metrics.h(45);

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () => _submitEntry(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white),
            SizedBox(width: metrics.spacing(6)),
            Text(
              config.submitButtonTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: metrics.text(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeAction(
    BuildContext context,
    ResponsiveMetrics metrics,
  ) {
    final config = mode.config;
    final double height =
        metrics.width < 360 ? metrics.h(38) : metrics.h(45);

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () => _submitEntry(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white),
            SizedBox(width: metrics.spacing(6)),
            Text(
              config.submitButtonTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: metrics.text(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActionButton(
    ResponsiveMetrics metrics,
    String text,
    IconData icon,
  ) {
    final isSmallScreen = metrics.width < 360;
    final double height = isSmallScreen ? metrics.h(38) : metrics.h(45);
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: metrics.spacing(8)),
        ),
        child: FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: metrics.size(15)),
              if (text.isNotEmpty) ...[
                SizedBox(width: metrics.spacing(4)),
                Text(
                  text,
                  style: TextStyle(fontSize: metrics.text(13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitEntry(BuildContext context) async {
    final result = await controller.submitEntry();

    if (!result.success) {
      switch (result.action) {
        case SaveAction.invalidAmount:
          WafferlyToast.showError(
            context,
            message: "Please enter a valid amount",
          );
          return;

        case SaveAction.noCategorySelected:
          WafferlyToast.showError(
            context,
            message: "Please select a category",
          );
          return;

        case SaveAction.noAccountSelected:
          WafferlyToast.showError(
            context,
            message: "Please select an account",
          );
          return;

        default:
          if (result.errorMessage != null) {
            WafferlyToast.showError(
              context,
              message: result.errorMessage!,
            );
          }
          return;
      }
    }

    WafferlyToast.showSuccess(
      context,
      message: "Transaction saved",
    );

    if (result.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: const Text('Choose how you want to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        Navigator.pop(context, true);
      }

      return;
    }
  }
}

enum _NotchedSide { left, right }

class _NotchedAddButton extends StatelessWidget {
  final double height;
  final double cutoutRadius;
  final double seam;
  final bool isExceptional;
  final bool enabled;
  final VoidCallback onAddTap;
  final VoidCallback onStarTap;

  const _NotchedAddButton({
    required this.height,
    required this.cutoutRadius,
    required this.seam,
    required this.isExceptional,
    required this.enabled,
    required this.onAddTap,
    required this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeText = Color(0xFF92400E);

    return ClipPath(
      clipper: _NotchedButtonClipper(
        side: _NotchedSide.left,
        cutoutRadius: cutoutRadius,
        seam: seam,
      ),
      child: Material(
        color: enabled ? const Color(0xFFFDE68A) : AppColors.cardSecondary,
        child: Row(
          children: [
            // Exceptional toggle: a property of the entry, always available.
            SizedBox(
              width: 54,
              height: height,
              // left padding keeps the star clear of the mic cut-out
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Tooltip(
                message: 'Exceptional',
                child: InkWell(
                  onTap: onStarTap,
                  child: Center(
                    child: Icon(
                      isExceptional
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isExceptional
                          ? Colors.amber
                          : (enabled ? activeText : Colors.white54),
                      size: 21,
                    ),
                  ),
                ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onAddTap,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Add',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: enabled ? activeText : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchedActionButton extends StatelessWidget {
  final double height;
  final _NotchedSide side;
  final double cutoutRadius;
  final double seam;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  const _NotchedActionButton({
    required this.height,
    required this.side,
    required this.cutoutRadius,
    required this.seam,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _NotchedButtonClipper(
        side: side,
        cutoutRadius: cutoutRadius,
        seam: seam,
      ),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: iconColor ?? foregroundColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _MicButton({
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF8B5CF6),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Rounded rectangle with a circular bite taken out of the edge that faces
/// the mic. The circle is centred on the seam between the two buttons, so
/// Done and Add are cut symmetrically.
class _NotchedButtonClipper extends CustomClipper<Path> {
  final _NotchedSide side;
  final double cutoutRadius;
  final double seam;

  const _NotchedButtonClipper({
    required this.side,
    required this.cutoutRadius,
    required this.seam,
  });

  @override
  Path getClip(Size size) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(10),
        ),
      );

    final centerX = side == _NotchedSide.right
        ? size.width + seam / 2
        : -seam / 2;

    final hole = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(centerX, size.height / 2),
          radius: cutoutRadius,
        ),
      );

    return Path.combine(PathOperation.difference, body, hole);
  }

  @override
  bool shouldReclip(covariant _NotchedButtonClipper oldClipper) {
    return oldClipper.side != side ||
        oldClipper.cutoutRadius != cutoutRadius ||
        oldClipper.seam != seam;
  }
}

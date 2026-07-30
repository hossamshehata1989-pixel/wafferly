import 'package:flutter/material.dart';

/// Visual identity for a financial entity card.
/// Contains the decorative background SVG and the accent color
/// used for tinting that SVG.
class FinancialEntityVisual {
  final String backgroundSvg;
  final Color surfaceAccent;

  const FinancialEntityVisual({
    required this.backgroundSvg,
    required this.surfaceAccent,
  });
}

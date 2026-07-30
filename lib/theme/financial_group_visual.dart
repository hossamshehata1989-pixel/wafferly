import 'package:flutter/material.dart';
import 'financial_entity_visual.dart';

class FinancialGroupVisual {
  final String icon;
  final String background;
  final Color color;

  const FinancialGroupVisual({
    required this.icon,
    required this.background,
    required this.color,
  });
}

extension FinancialGroupVisualMapper on FinancialGroupVisual {
  FinancialEntityVisual toEntityVisual() {
    return FinancialEntityVisual(
      backgroundSvg: background,
      surfaceAccent: color,
    );
  }
}

// lib/theme/responsive_metrics.dart

import 'package:flutter/material.dart';

/// نظام قياسي Responsive لضبط الأحجام والأبعاد بناءً على عرض وارتفاع الشاشة.
class ResponsiveMetrics {
  /// عامل القياس الأساسي (مشتق من العرض)
  final double scale;

  /// عامل القياس للخطوط
  final double textScale;

  /// عامل القياس للأيقونات والأزرار (أفقي)
  final double sizeScale;

  /// عامل القياس للمسافات الأفقية
  final double spacingScale;

  /// عامل القياس للارتفاعات — مشتق من ارتفاع الشاشة
  /// iPhone SE (667px) → 0.75 | Pixel 4 (873px) → 0.98 | iPhone 14 (892px) → 1.0
  final double heightScale;

  const ResponsiveMetrics._({
    required this.scale,
    required this.textScale,
    required this.sizeScale,
    required this.spacingScale,
    required this.heightScale,
  });

  factory ResponsiveMetrics.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Scale مبني على العرض — مرجع: Pixel 8 (~411dp)
    final rawScale = width / 411.0;
    final scale = rawScale.clamp(0.85, 1.25);

    // Scale مبني على الارتفاع — مرجع: iPhone 14 (~892dp)
    final rawHeightScale = height / 892.0;
    final heightScale = rawHeightScale.clamp(0.75, 1.15);

    return ResponsiveMetrics._(
      scale: scale,
      textScale: scale.clamp(0.85, 1.2),
      sizeScale: scale.clamp(0.85, 1.3),
      spacingScale: scale.clamp(0.85, 1.25),
      heightScale: heightScale,
    );
  }

  /// قيمة متجاوبة بناءً على sizeScale (أزرار، أيقونات — أفقي)
  double size(double reference) => reference * sizeScale;

  /// قيمة متجاوبة بناءً على textScale (خطوط)
  double text(double reference) => reference * textScale;

  /// قيمة متجاوبة بناءً على spacingScale (padding أفقي، margin)
  double spacing(double reference) => reference * spacingScale;

  /// قيمة متجاوبة بناءً على heightScale (ارتفاعات العناصر — رأسي)
  /// استخدم هذه لكل height ثابت في الشاشة
  double h(double reference) => reference * heightScale;
}

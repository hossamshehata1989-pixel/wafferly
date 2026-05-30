// lib/theme/responsive_metrics.dart

import 'package:flutter/material.dart';

/// نظام قياسي Responsive لضبط الأحجام والأبعاد بناءً على عرض الشاشة.
class ResponsiveMetrics {
  /// عامل القياس الأساسي (مشتق من العرض)
  final double scale;

  /// عامل القياس للخطوط (يُطبق على `fontSize`)
  final double textScale;

  /// عامل القياس للأيقونات والأزرار (يُطبق على `width`, `height`, `iconSize`)
  final double sizeScale;

  /// عامل القياس للمسافات (paddings, margins, spacings)
  final double spacingScale;

  const ResponsiveMetrics._({
    required this.scale,
    required this.textScale,
    required this.sizeScale,
    required this.spacingScale,
  });

  /// مصنع لإنشاء القيم بناءً على `BuildContext`
  factory ResponsiveMetrics.of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // النطاق: الحد الأدنى 0.85 (لشاشات صغيرة جداً مثل 350dp)، الحد الأقصى 1.25 (لشاشات عريضة)
    final rawScale = width / 411.0; // 411 هو عرض مرجعي (Pixel 8 تقريباً)
    final scale = rawScale.clamp(0.85, 1.25);

    return ResponsiveMetrics._(
      scale: scale,
      textScale: scale.clamp(0.85, 1.2), // النصوص لا تحتاج تضخيم كبير
      sizeScale: scale.clamp(
        0.85,
        1.3,
      ), // الأزرار والأيقونات يمكن أن تكبر قليلاً
      spacingScale: scale.clamp(0.85, 1.25), // الهوامش والمسافات
    );
  }

  /// تحويل قيمة مرجعية إلى قيمة متجاوبة بناءً على `sizeScale`
  double size(double reference) => reference * sizeScale;

  /// تحويل قيمة مرجعية للخط إلى قيمة متجاوبة بناءً على `textScale`
  double text(double reference) => reference * textScale;

  /// تحويل قيمة مرجعية للمسافات إلى قيمة متجاوبة بناءً على `spacingScale`
  double spacing(double reference) => reference * spacingScale;

  /// الحصول على حجم زر الآلة الحاسبة (يعتمد على ارتفاع الشاشة كما كان أصلاً،
  /// لكننا نستخدم `size` لتعديل القيمة الأساسية إذا أردنا، ولكن الأفضل الاحتفاظ بالسلوك الأصلي.
  /// سنعيد القيمة الأصلية للزر محسوبة من ارتفاع الشاشة لكن مع تطبيق `size` على الحرف.
  /// ملاحظة: هذه الطريقة لن تستخدم هنا، بل سنحتفظ بحساب `buttonSize` الأصلي.
}

// lib/theme/responsive_metrics.dart

import 'package:flutter/material.dart';

/// نظام Responsive متكامل:
/// - مرجع العرض = 390dp (متوازن لأجهزة Android الحديثة و iOS)
/// - يدعم نقاط التوقف (Mobile, Tablet, Desktop)
/// - يحسب مقاييس التكبير/التصغير مع حدود آمان
class ResponsiveMetrics {
  // ------------------------------------------------------------
  // 1. الثوابت الأساسية
  // ------------------------------------------------------------
  static const double _referenceWidth = 390.0; // المرجع الجديد (بدلاً من 411)
  static const double _referenceHeight = 892.0; // مرجع الارتفاع (iPhone 14)

  // حدود التكبير القصوى والدنيا (تم تخفيض lowerBound إلى 0.8 لدعم iPhone SE 320px)
  static const double _minScale = 0.85;
  static const double _maxScale = 1.5;
  static const double _minTextScale = 0.8;
  static const double _maxTextScale = 1.3;

  // ------------------------------------------------------------
  // 2. نقاط التوقف (Breakpoints) - حسب أفضل الممارسات
  // ------------------------------------------------------------
  static const double mobileBreakpoint = 600; // < 600 → موبايل
  static const double tabletBreakpoint = 840; // 600 - 839 → تابلت
  // ≥ 840 → ديسكتوب / ويب

  // ------------------------------------------------------------
  // 3. الخصائص المحسوبة (لكل BuildContext)
  // ------------------------------------------------------------
  final double width; // عرض الشاشة (dp)
  final double height; // ارتفاع الشاشة (dp)
  final double scale; // عامل التكبير الأفقي
  final double textScale; // عامل تكبير النصوص
  final double sizeScale; // عامل تكبير للأزرار/الأيقونات
  final double spacingScale; // عامل للمسافات الأفقية
  final double heightScale; // عامل للارتفاعات (من ارتفاع الشاشة)

  const ResponsiveMetrics._({
    required this.width,
    required this.height,
    required this.scale,
    required this.textScale,
    required this.sizeScale,
    required this.spacingScale,
    required this.heightScale,
  });

  // ------------------------------------------------------------
  // 4. المصنع (Factory) - يحسب القيم من MediaQuery
  // ------------------------------------------------------------
  factory ResponsiveMetrics.of(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    // التكبير الأفقي (بالنسبة للمرجع 390)
    double rawScale = width / _referenceWidth;
    double scale = rawScale.clamp(_minScale, _maxScale);

    // تكبير النصوص (قد يختلف)
    double textScale = scale.clamp(_minTextScale, _maxTextScale);

    // تكبير الأيقونات/الأزرار (يمكن أن يكون أكثر مرونة)
    double sizeScale = scale.clamp(_minScale, 1.6);

    // تكبير المسافات
    double spacingScale = scale.clamp(_minScale, 1.4);

    // التكبير العمودي (بالنسبة للمرجع 892)
    double heightScale = (height / _referenceHeight).clamp(0.7, 1.2);

    return ResponsiveMetrics._(
      width: width,
      height: height,
      scale: scale,
      textScale: textScale,
      sizeScale: sizeScale,
      spacingScale: spacingScale,
      heightScale: heightScale,
    );
  }

  // ------------------------------------------------------------
  // 5. الدوال المساعدة (لتطبيق المقاييس)
  // ------------------------------------------------------------
  double size(double reference) => reference * sizeScale;
  double text(double reference) => reference * textScale;
  double spacing(double reference) => reference * spacingScale;
  double h(double reference) => reference * heightScale;

  // دالة للقيم المطلقة مع إمكانية تجاوز المقياس (اختياري)
  double custom(double reference, {double? customScale}) =>
      reference * (customScale ?? scale);

  // ------------------------------------------------------------
  // 6. دوال نقاط التوقف (لتغيير الـ UI بناءً على حجم الشاشة)
  // ------------------------------------------------------------
  bool get isMobile => width < mobileBreakpoint;
  bool get isTablet => width >= mobileBreakpoint && width < tabletBreakpoint;
  bool get isDesktop => width >= tabletBreakpoint;

  // اتجاه الشاشة (أفقي/رأسي)
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;

  // ------------------------------------------------------------
  // 7. (اختياري) دالة لبناء واجهة متجاوبة باستخدام نقاط التوقف
  // مثال: ResponsiveMetrics.build(context, mobile: ..., tablet: ..., desktop: ...)
  // ------------------------------------------------------------
  static T build<T>(
    BuildContext context, {
    required T Function() mobile,
    T Function()? tablet,
    T Function()? desktop,
  }) {
    final metrics = ResponsiveMetrics.of(context);
    if (metrics.isDesktop && desktop != null) return desktop();
    if (metrics.isTablet && tablet != null) return tablet();
    return mobile();
  }
}

// lib/theme/responsive_metrics.dart

import 'package:flutter/material.dart';

/// نظام Responsive متكامل:
/// - مرجع العرض = 390dp
/// - يدعم Mobile / Tablet / Desktop
/// - يحسب مقاييس التكبير والتصغير
class ResponsiveMetrics {
  // ------------------------------------------------------------
  // 1. Constants
  // ------------------------------------------------------------

  static const double _referenceWidth = 390.0;
  static const double _referenceHeight = 892.0;

  static const double _minScale = 0.85;
  static const double _maxScale = 1.5;

  static const double _minTextScale = 0.8;
  static const double _maxTextScale = 1.3;

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;

  // ------------------------------------------------------------
  // 2. Properties
  // ------------------------------------------------------------

  final double width;
  final double height;

  final double scale;
  final double textScale;
  final double sizeScale;
  final double spacingScale;
  final double heightScale;

  ResponsiveMetrics._({
    required this.width,
    required this.height,
    required this.scale,
    required this.textScale,
    required this.sizeScale,
    required this.spacingScale,
    required this.heightScale,
  });

  // ------------------------------------------------------------
  // Factory
  // ------------------------------------------------------------

  factory ResponsiveMetrics.of(BuildContext context) {
    final media = MediaQuery.of(context);

    final width = media.size.width;
    final height = media.size.height;

    final scale = (width / _referenceWidth).clamp(_minScale, _maxScale);

    final textScale = scale.clamp(_minTextScale, _maxTextScale);

    final sizeScale = scale.clamp(_minScale, 1.6);

    final spacingScale = scale.clamp(_minScale, 1.4);

    final heightScale = (height / _referenceHeight).clamp(0.7, 1.2);

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
  // Helpers
  // ------------------------------------------------------------

  double size(double reference) => reference * sizeScale;

  double text(double reference) => reference * textScale;

  double spacing(double reference) => reference * spacingScale;

  double h(double reference) => reference * heightScale;

  double custom(double reference, {double? customScale}) {
    return reference * (customScale ?? scale);
  }

  // ------------------------------------------------------------
  // Breakpoints
  // ------------------------------------------------------------

  bool get isMobile => width < mobileBreakpoint;

  bool get isTablet => width >= mobileBreakpoint && width < tabletBreakpoint;

  bool get isDesktop => width >= tabletBreakpoint;

  bool get isPortrait => height > width;

  bool get isLandscape => width > height;

  /// أجهزة قصيرة مثل:
  /// iPhone SE / iPhone 8 / Pixel 4a
  bool get isCompactHeight => height < 700;

  // ------------------------------------------------------------
  // Design Tokens
  // ------------------------------------------------------------

  late final typography = _ResponsiveTypography(this);

  late final icon = _ResponsiveIcon(this);

  late final card = _ResponsiveCard(this);

  late final input = _ResponsiveInput(this);

  late final button = _ResponsiveButton(this);

  late final space = _ResponsiveSpacing(this);

  late final radius = _ResponsiveRadius(this);

  // ------------------------------------------------------------
  // Responsive Builder
  // ------------------------------------------------------------

  static T build<T>(
    BuildContext context, {
    required T Function() mobile,
    T Function()? tablet,
    T Function()? desktop,
  }) {
    final metrics = ResponsiveMetrics.of(context);

    if (metrics.isDesktop && desktop != null) {
      return desktop();
    }

    if (metrics.isTablet && tablet != null) {
      return tablet();
    }

    return mobile();
  }
}

// ------------------------------------------------------------
// Typography
// ------------------------------------------------------------

class _ResponsiveTypography {
  final ResponsiveMetrics m;

  const _ResponsiveTypography(this.m);

  double get caption => m.isCompactHeight ? m.text(10) : m.text(10);

  double get body => m.isCompactHeight ? m.text(13) : m.text(14);

  double get title => m.isCompactHeight ? m.text(16) : m.text(18);

  double get headline => m.text(26);

  double get accountPicker => m.isCompactHeight ? 24 : 28;
}

// ------------------------------------------------------------
// Icons
// ------------------------------------------------------------

class _ResponsiveIcon {
  final ResponsiveMetrics m;

  const _ResponsiveIcon(this.m);

  double get small => m.size(18);

  double get medium => m.isCompactHeight ? m.size(18) : m.size(24);

  double get large => m.size(32);

  double get hero => m.size(56);

  double get xl => m.size(40);

  double get accountIcon => m.isCompactHeight ? m.size(34) : m.size(42);

  double get accountPicker => m.isCompactHeight ? 26 : 30;

  double get avatar => m.isCompactHeight ? m.size(30) : m.size(38);
}

// ------------------------------------------------------------
// Cards
// ------------------------------------------------------------

class _ResponsiveCard {
  final ResponsiveMetrics m;

  const _ResponsiveCard(this.m);

  double get accountTypeHeight => m.isCompactHeight ? m.h(70) : m.h(82);

  double get previewHeight => m.h(92);
}

// ------------------------------------------------------------
// Inputs
// ------------------------------------------------------------

class _ResponsiveInput {
  final ResponsiveMetrics m;

  const _ResponsiveInput(this.m);

  double get height => m.isCompactHeight ? m.h(40) : m.h(48);

  double get multilineHeight => height;

  double get verticalPadding => m.isCompactHeight ? 6 : 8;
}

// ------------------------------------------------------------
// Buttons
// ------------------------------------------------------------

class _ResponsiveButton {
  final ResponsiveMetrics m;

  const _ResponsiveButton(this.m);

  double get height => m.isCompactHeight ? 46 : 54;
}

// ------------------------------------------------------------
// Spacing
// ------------------------------------------------------------

class _ResponsiveSpacing {
  final ResponsiveMetrics m;

  const _ResponsiveSpacing(this.m);

  double get xs => m.isCompactHeight ? m.spacing(2) : m.spacing(4);

  double get sm => m.isCompactHeight ? m.spacing(6) : m.spacing(8);

  double get md => m.isCompactHeight ? m.spacing(12) : m.spacing(16);

  double get lg => m.isCompactHeight ? m.spacing(18) : m.spacing(24);

  double get xl => m.isCompactHeight ? m.spacing(24) : m.spacing(32);
}

// ------------------------------------------------------------
// Radius
// ------------------------------------------------------------

class _ResponsiveRadius {
  final ResponsiveMetrics m;

  const _ResponsiveRadius(this.m);

  double get sm => m.size(8);

  double get md => m.size(12);

  double get lg => m.size(16);

  double get xl => m.size(24);

  double get xxl => m.size(32);
}

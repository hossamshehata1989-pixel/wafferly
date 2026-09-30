import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable presentation widget for a credit-card visual.
/// The selected visual is metadata on CreditCardProfile; this widget only renders it.
class CreditCardVisual extends StatelessWidget {
  const CreditCardVisual({
    super.key,
    required this.visual,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String visual;
  final double? width;
  final double? height;
  final BoxFit fit;

  static const _assets = <String, String>{
    'classic': 'assets/images/credit_cards/classic.svg',
    'midnight': 'assets/images/credit_cards/midnight.svg',
    'aurora': 'assets/images/credit_cards/aurora.svg',
  };

  String get _asset => _assets[visual] ?? _assets['classic']!;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

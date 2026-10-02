import 'package:flutter/material.dart';

import 'wafferly_financial_card.dart';

/// Backward-compatible visual-only widget.
/// Existing screens can keep using CreditCardVisual while the artwork itself
/// is now owned by Wafferly and selected by visual id.
class CreditCardVisual extends StatelessWidget {
  const CreditCardVisual({
    super.key,
    required this.visual,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String visual;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final kind = visual.startsWith('debit_')
        ? WafferlyCardKind.debit
        : visual.startsWith('prepaid_')
            ? WafferlyCardKind.prepaid
            : visual.startsWith('virtual_')
                ? WafferlyCardKind.virtual
                : visual.startsWith('charge_')
                    ? WafferlyCardKind.charge
                    : WafferlyCardKind.credit;

    return WafferlyFinancialCard(
      kind: kind,
      visual: visual,
      width: width,
      height: height,
      fit: fit,
      showFinancialData: false,
    );
  }
}

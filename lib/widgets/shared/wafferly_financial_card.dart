import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wafferly's visual identity for financial cards.
///
/// The artwork is owned by Wafferly. Bank/provider names, last four digits and
/// financial values are always rendered by Flutter so the visual is reusable.
enum WafferlyCardKind { credit, debit, prepaid, virtual, charge }

class WafferlyCardVisualSpec {
  const WafferlyCardVisualSpec({
    required this.id,
    required this.name,
    required this.kind,
    required this.colors,
    this.accent,
  });

  final String id;
  final String name;
  final WafferlyCardKind kind;
  final List<Color> colors;
  final Color? accent;
}

class WafferlyCardVisuals {
  static const List<WafferlyCardVisualSpec> credit = [
    WafferlyCardVisualSpec(id: 'credit_midnight', name: 'Midnight', kind: WafferlyCardKind.credit, colors: [Color(0xFF062E38), Color(0xFF007F72)], accent: Color(0xFF20D7C7)),
    WafferlyCardVisualSpec(id: 'credit_aurora', name: 'Aurora', kind: WafferlyCardKind.credit, colors: [Color(0xFF26105C), Color(0xFF8A1D77)], accent: Color(0xFFD36BFF)),
    WafferlyCardVisualSpec(id: 'credit_ruby', name: 'Ruby', kind: WafferlyCardKind.credit, colors: [Color(0xFF4A071B), Color(0xFFD52242)], accent: Color(0xFFFF6A83)),
    WafferlyCardVisualSpec(id: 'credit_ocean', name: 'Ocean', kind: WafferlyCardKind.credit, colors: [Color(0xFF061B52), Color(0xFF007BD8)], accent: Color(0xFF48C8FF)),
    WafferlyCardVisualSpec(id: 'credit_forest', name: 'Forest', kind: WafferlyCardKind.credit, colors: [Color(0xFF063D2D), Color(0xFF1B7D55)], accent: Color(0xFF66E6A9)),
    WafferlyCardVisualSpec(id: 'credit_sand', name: 'Sand', kind: WafferlyCardKind.credit, colors: [Color(0xFF4B3920), Color(0xFFC99B52)], accent: Color(0xFFFFD98A)),
  ];

  static const List<WafferlyCardVisualSpec> debit = [
    WafferlyCardVisualSpec(id: 'debit_ocean', name: 'Ocean', kind: WafferlyCardKind.debit, colors: [Color(0xFF061D5C), Color(0xFF087BD6)], accent: Color(0xFF42C7FF)),
    WafferlyCardVisualSpec(id: 'debit_forest', name: 'Forest', kind: WafferlyCardKind.debit, colors: [Color(0xFF073E30), Color(0xFF2B8D68)], accent: Color(0xFF75E7B0)),
    WafferlyCardVisualSpec(id: 'debit_light', name: 'Light', kind: WafferlyCardKind.debit, colors: [Color(0xFFEAF0F2), Color(0xFFBFCBD1)], accent: Color(0xFF30465A)),
    WafferlyCardVisualSpec(id: 'debit_graphite', name: 'Graphite', kind: WafferlyCardKind.debit, colors: [Color(0xFF111821), Color(0xFF46515C)], accent: Color(0xFFB8C5D1)),
  ];

  static const List<WafferlyCardVisualSpec> prepaid = [
    WafferlyCardVisualSpec(id: 'prepaid_purple', name: 'Purple', kind: WafferlyCardKind.prepaid, colors: [Color(0xFF35117A), Color(0xFF8B28DA)], accent: Color(0xFFD18AFF)),
    WafferlyCardVisualSpec(id: 'prepaid_teal', name: 'Teal', kind: WafferlyCardKind.prepaid, colors: [Color(0xFF075B69), Color(0xFF16B8C0)], accent: Color(0xFF7AF2EF)),
    WafferlyCardVisualSpec(id: 'prepaid_sunset', name: 'Sunset', kind: WafferlyCardKind.prepaid, colors: [Color(0xFF7A2410), Color(0xFFFF8B2C)], accent: Color(0xFFFFD38A)),
    WafferlyCardVisualSpec(id: 'prepaid_blue', name: 'Blue', kind: WafferlyCardKind.prepaid, colors: [Color(0xFF0B2D73), Color(0xFF1A6CDA)], accent: Color(0xFF7DB8FF)),
  ];

  static const List<WafferlyCardVisualSpec> virtual = [
    WafferlyCardVisualSpec(id: 'virtual_digital', name: 'Digital', kind: WafferlyCardKind.virtual, colors: [Color(0xFF0B164A), Color(0xFF2637A6)], accent: Color(0xFF6F8CFF)),
    WafferlyCardVisualSpec(id: 'virtual_neon', name: 'Neon', kind: WafferlyCardKind.virtual, colors: [Color(0xFF10122B), Color(0xFF7D197E)], accent: Color(0xFFFF66D8)),
    WafferlyCardVisualSpec(id: 'virtual_ice', name: 'Ice', kind: WafferlyCardKind.virtual, colors: [Color(0xFF0B3043), Color(0xFF38BBD1)], accent: Color(0xFFA0F6FF)),
  ];

  static const List<WafferlyCardVisualSpec> charge = [
    WafferlyCardVisualSpec(id: 'charge_gold', name: 'Gold', kind: WafferlyCardKind.charge, colors: [Color(0xFF17130C), Color(0xFF6D4A17)], accent: Color(0xFFFFD36E)),
    WafferlyCardVisualSpec(id: 'charge_black', name: 'Black', kind: WafferlyCardKind.charge, colors: [Color(0xFF101010), Color(0xFF343434)], accent: Color(0xFFE5E5E5)),
  ];

  static List<WafferlyCardVisualSpec> forKind(WafferlyCardKind kind) => switch (kind) {
        WafferlyCardKind.credit => credit,
        WafferlyCardKind.debit => debit,
        WafferlyCardKind.prepaid => prepaid,
        WafferlyCardKind.virtual => virtual,
        WafferlyCardKind.charge => charge,
      };

  static WafferlyCardVisualSpec resolve(String? id, WafferlyCardKind kind) {
    final options = forKind(kind);
    return options.firstWhere(
      (item) => item.id == id,
      orElse: () => options.first,
    );
  }
}

class WafferlyFinancialCard extends StatelessWidget {
  const WafferlyFinancialCard({
    super.key,
    required this.kind,
    required this.visual,
    this.cardName,
    this.provider,
    this.last4,
    this.currency = 'EGP',
    this.available,
    this.creditLimit,
    this.thisMonthInstallment,
    this.totalInstallment,
    this.usedRatio,
    this.showFinancialData = true,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final WafferlyCardKind kind;
  final String visual;
  final String? cardName;
  final String? provider;
  final String? last4;
  final String currency;
  final double? available;
  final double? creditLimit;
  final double? thisMonthInstallment;
  final double? totalInstallment;
  final double? usedRatio;
  final bool showFinancialData;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final spec = WafferlyCardVisuals.resolve(visual, kind);
    final content = AspectRatio(
      aspectRatio: 1.586,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 14, offset: Offset(0, 7)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _WafferlyCardPainter(spec: spec, kind: kind)),
                  if (cardName != null) _position(w, h, 0.075, 0.065, 0.46, 0.105, _text(cardName!, 17, FontWeight.w900)),
                  if (provider != null && provider!.trim().isNotEmpty)
                    _position(w, h, 0.075, 0.165, 0.48, 0.075, _text(provider!, 8.5, FontWeight.w600, color: Colors.white70)),
                  if (last4 != null && last4!.trim().isNotEmpty)
                    _position(w, h, 0.075, 0.23, 0.30, 0.08, _text('•••• ${last4!.trim()}', 9, FontWeight.w700, color: Colors.white70)),
                  if (showFinancialData && kind == WafferlyCardKind.credit) ...[
                    if (available != null) _position(w, h, 0.70, 0.06, 0.25, 0.16, _stat('Available', _money(available!), const Color(0xFF39E6B0))),
                    if (creditLimit != null) _position(w, h, 0.70, 0.205, 0.25, 0.16, _stat('Credit Limit', _money(creditLimit!), Colors.white)),
                    if (thisMonthInstallment != null) _position(w, h, 0.34, 0.43, 0.29, 0.20, _stat('This Month Installment', _money(thisMonthInstallment!), const Color(0xFFFF2D6F), big: true)),
                    if (totalInstallment != null) _position(w, h, 0.65, 0.43, 0.29, 0.20, _stat('Total Installment', _money(totalInstallment!), Colors.white, big: true)),
                    if (usedRatio != null) _position(w, h, 0.34, 0.70, 0.59, 0.15, _usage(usedRatio!)),
                  ],
                  if (showFinancialData && kind != WafferlyCardKind.credit && available != null)
                    _position(w, h, 0.54, 0.39, 0.38, 0.19, _stat('Balance', _money(available!), Colors.white, big: true)),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: FittedBox(fit: fit, child: SizedBox(width: 320, height: 202, child: content)));
    }
    return content;
  }

  Widget _position(double w, double h, double x, double y, double width, double height, Widget child) =>
      Positioned(left: w * x, top: h * y, width: w * width, height: h * height, child: child);

  Widget _text(String value, double size, FontWeight weight, {Color color = Colors.white}) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: size, fontWeight: weight)));

  Widget _stat(String label, String value, Color color, {bool big = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .32), borderRadius: BorderRadius.circular(9)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 7.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, maxLines: 1, style: TextStyle(color: color, fontSize: big ? 15 : 11, fontWeight: FontWeight.w900))),
        ]),
      );

  Widget _usage(double ratio) {
    final value = ratio.clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Used', style: TextStyle(color: Colors.white70, fontSize: 7.5)),
        Text('${(value * 100).round()}% used', style: const TextStyle(color: Color(0xFFFF3D81), fontSize: 7.5, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 3),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: value, minHeight: 5, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3D81)))),
    ]);
  }

  String _money(double value) => '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)} $currency';
}

class WafferlyCardVisualPicker extends StatelessWidget {
  const WafferlyCardVisualPicker({super.key, required this.kind, required this.value, required this.onChanged});

  final WafferlyCardKind kind;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = WafferlyCardVisuals.forKind(kind);
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = option.id == value;
          return GestureDetector(
            onTap: () => onChanged(option.id),
            child: SizedBox(
              width: 138,
              child: Column(children: [
                Expanded(
                  child: Stack(children: [
                    Positioned.fill(child: WafferlyFinancialCard(kind: kind, visual: option.id, showFinancialData: false)),
                    if (selected)
                      Positioned(right: 6, top: 6, child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFF35E0B5), shape: BoxShape.circle), child: const Icon(Icons.check, size: 15, color: Colors.black))),
                  ]),
                ),
                const SizedBox(height: 5),
                Text(option.name, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _WafferlyCardPainter extends CustomPainter {
  const _WafferlyCardPainter({required this.spec, required this.kind});
  final WafferlyCardVisualSpec spec;
  final WafferlyCardKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: spec.colors).createShader(rect);
    canvas.drawRect(rect, paint);

    final accent = Paint()..color = (spec.accent ?? Colors.white).withValues(alpha: .22);
    final seed = spec.id.hashCode.abs();
    final shift = (seed % 80).toDouble();
    canvas.drawCircle(Offset(size.width * .82 + shift * .02, size.height * .30), size.height * .28, accent);
    canvas.drawCircle(Offset(size.width * .93 - shift * .01, size.height * .38), size.height * .24, Paint()..color = (spec.accent ?? Colors.white).withValues(alpha: .14));

    final linePaint = Paint()..color = Colors.white.withValues(alpha: .07)..strokeWidth = 1.5;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (.12 + i * .18);
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y + size.height * .06), linePaint);
    }

    // Wafferly's neutral card chip. It is artwork, not card data.
    final chip = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .075, size.height * .32, size.width * .16, size.height * .23), const Radius.circular(7));
    canvas.drawRRect(chip, Paint()..color = const Color(0xFFE8C35B));
    final chipLine = Paint()..color = const Color(0xFF9A7924)..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * .155, size.height * .32), Offset(size.width * .155, size.height * .55), chipLine);
    canvas.drawLine(Offset(size.width * .075, size.height * .435), Offset(size.width * .235, size.height * .435), chipLine);

    // Abstract network mark: intentionally brand-neutral.
    final r = size.height * .15;
    final c1 = Offset(size.width * .82, size.height * .34);
    final c2 = Offset(size.width * .89, size.height * .34);
    canvas.drawCircle(c1, r, Paint()..color = (spec.accent ?? Colors.white).withValues(alpha: .80));
    canvas.drawCircle(c2, r, Paint()..color = Colors.white.withValues(alpha: .34));
  }

  @override
  bool shouldRepaint(covariant _WafferlyCardPainter oldDelegate) => oldDelegate.spec.id != spec.id;
}

import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Universal visual/layout contract for Wafferly financial cards.
///
/// This file is intentionally independent from CreditCard, DebitCard,
/// PrepaidCard, or any specific domain model.
///
/// The same renderer can be used for:
/// - Credit cards
/// - Debit cards
/// - Prepaid cards
/// - Virtual cards
/// - Charge cards
/// - Other financially-linked cards
///
/// IMPORTANT:
/// The SVG artwork is only the visual background.
/// Text/icons are positioned using the layout assigned to that visual.
/// Therefore every SVG can have its own safe/content zones.

enum WafferlyCardKind {
  credit,
  debit,
  prepaid,
  virtual,
  charge,
  other,
}

enum CardTextSlot {
  issuer,
  cardName,
  cardholder,
  maskedNumber,
  expiry,
  network,
  status,
  balance,
  available,
  creditLimit,
  usedAmount,
  usedPercent,
  monthlyInstallment,
  totalInstallment,
  outstanding,
  thisMonthDue,
  nextMonthDue,
  minimumPayment,
  overdue,
  statementCycle,
  currency,
}

enum CardZone {
  identity,
  financialPrimary,
  financialSecondary,
  usage,
  status,
  footer,
  custom,
}

/// Normalized rectangle: x/y/width/height are all 0..1.
///
/// Using normalized coordinates makes the same layout work at any size.
class CardVisualZone {
  const CardVisualZone({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final Alignment alignment;
  final EdgeInsets padding;

  Rect resolve(Size size) {
    return Rect.fromLTWH(
      size.width * x,
      size.height * y,
      size.width * width,
      size.height * height,
    );
  }

  bool get isValid =>
      x >= 0 &&
      y >= 0 &&
      width > 0 &&
      height > 0 &&
      x + width <= 1 &&
      y + height <= 1;
}

/// Defines where a semantic field is allowed to appear for one SVG visual.
class CardVisualSlot {
  const CardVisualSlot({
    required this.zone,
    required this.area,
    this.maxLines = 1,
    this.minFontScale = 0.72,
    this.maxFontScale = 1.0,
  });

  final CardZone zone;
  final CardVisualZone area;
  final int maxLines;
  final double minFontScale;
  final double maxFontScale;
}

/// A complete layout contract for one SVG/card artwork.
class CardVisualLayout {
  const CardVisualLayout({
    required this.visualId,
    required this.aspectRatio,
    required this.slots,
    this.reservedZones = const <CardVisualZone>[],
  });

  final String visualId;
  final double aspectRatio;
  final Map<CardTextSlot, CardVisualSlot> slots;

  /// Areas occupied by artwork elements such as chip, network logo,
  /// decorative circles, holograms, or other non-text graphics.
  final List<CardVisualZone> reservedZones;

  CardVisualSlot? slot(CardTextSlot field) => slots[field];

  bool supports(CardTextSlot field) => slots.containsKey(field);

  /// Basic validation for normalized coordinates.
  List<String> validate() {
    final errors = <String>[];

    if (visualId.trim().isEmpty) {
      errors.add('visualId cannot be empty.');
    }

    if (aspectRatio <= 0) {
      errors.add('aspectRatio must be greater than zero.');
    }

    for (final entry in slots.entries) {
      if (!entry.value.area.isValid) {
        errors.add('Invalid zone for ${entry.key}.');
      }
    }

    for (final zone in reservedZones) {
      if (!zone.isValid) {
        errors.add('Invalid reserved zone.');
      }
    }

    return errors;
  }
}

/// Visual metadata + layout.
class WafferlyCardVisual {
  static const List<WafferlyCardKind> allKinds = <WafferlyCardKind>[
    WafferlyCardKind.credit,
    WafferlyCardKind.debit,
    WafferlyCardKind.prepaid,
    WafferlyCardKind.virtual,
    WafferlyCardKind.charge,
    WafferlyCardKind.other,
  ];

  const WafferlyCardVisual({
    required this.id,
    required this.svgAsset,
    required this.layout,
    this.supportedKinds = const <WafferlyCardKind>[
      WafferlyCardKind.credit,
      WafferlyCardKind.debit,
      WafferlyCardKind.prepaid,
      WafferlyCardKind.virtual,
      WafferlyCardKind.charge,
      WafferlyCardKind.other,
    ],
  });

  final String id;
  final String svgAsset;
  final CardVisualLayout layout;
  final List<WafferlyCardKind> supportedKinds;

  bool supportsKind(WafferlyCardKind kind) => supportedKinds.contains(kind);
}

/// Universal registry for all Wafferly card visuals.
class WafferlyCardVisualRegistry {
  WafferlyCardVisualRegistry({
    Iterable<WafferlyCardVisual> visuals = const [],
  }) {
    for (final visual in visuals) {
      register(visual);
    }
  }

  final Map<String, WafferlyCardVisual> _visuals =
      <String, WafferlyCardVisual>{};

  void register(WafferlyCardVisual visual) {
    final errors = visual.layout.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Invalid card visual "${visual.id}": ${errors.join(' ')}',
      );
    }

    _visuals[visual.id] = visual;
  }

  WafferlyCardVisual? find(String visualId) => _visuals[visualId];

  WafferlyCardVisual resolve({
    required String? visualId,
    required WafferlyCardKind kind,
  }) {
    final requested = visualId == null ? null : find(visualId);

    if (requested != null && requested.supportsKind(kind)) {
      return requested;
    }

    final compatible = _visuals.values.where(
      (visual) => visual.supportsKind(kind),
    );

    if (compatible.isNotEmpty) {
      return compatible.first;
    }

    throw StateError(
      'No Wafferly card visual is registered for $kind.',
    );
  }

  List<WafferlyCardVisual> get all =>
      List<WafferlyCardVisual>.unmodifiable(_visuals.values);
}

/// Returns the layout contract for the selected SVG visual.
CardVisualLayout wafferlyCardLayoutForVisual(String visualId) {
  switch (visualId.trim().toLowerCase()) {
    case 'midnight':
      return _midnightCardLayout;
    case 'aurora':
      return _auroraCardLayout;
    case 'classic':
    default:
      return _classicCardLayout;
  }
}

/// Artwork-occupied areas (normalized to the 320x200 canvas).
const List<CardVisualZone> _standardReservedZones = <CardVisualZone>[
  CardVisualZone(x: .075, y: .235, width: .19, height: .205), // chip
  CardVisualZone(x: .77, y: .19, width: .20, height: .25), // network circles
  CardVisualZone(x: .075, y: .71, width: .31, height: .20), // brand label
];

/// Empty areas of the artwork, used for data.
/// - Identity is top-left.
/// - Masked number is next to the chip (right side).
/// - Financial secondary (Available/Limit) is top-right above circles.
/// - Installments are in the middle.
/// - Usage bar is at the bottom.
/// - Cycle info (Statement/Due) is bottom-left under the chip.
const Map<CardTextSlot, CardVisualSlot> _standardSlots =
    <CardTextSlot, CardVisualSlot>{
  // --- Identity (Top Left) ---
  CardTextSlot.cardName: CardVisualSlot(
    zone: CardZone.identity,
    area: CardVisualZone(x: .08, y: .08, width: .50, height: .12),
  ),
  CardTextSlot.issuer: CardVisualSlot(
    zone: CardZone.identity,
    area: CardVisualZone(x: .08, y: .18, width: .50, height: .09),
    minFontScale: .65,
  ),

  // --- Masked Number (next to chip, on the right side in the empty area) ---
  CardTextSlot.maskedNumber: CardVisualSlot(
    zone: CardZone.identity,
    area: CardVisualZone(x: .30, y: .30, width: .45, height: .12),
    maxLines: 1,
    minFontScale: .62,
  ),

  // --- Financial Secondary (Top Right) ---
  CardTextSlot.available: CardVisualSlot(
    zone: CardZone.financialSecondary,
    area: CardVisualZone(x: .70, y: .04, width: .26, height: .11),
    maxLines: 2,
    minFontScale: .62,
  ),
  CardTextSlot.creditLimit: CardVisualSlot(
    zone: CardZone.financialSecondary,
    area: CardVisualZone(x: .70, y: .15, width: .26, height: .11),
    maxLines: 2,
    minFontScale: .62,
  ),

  // --- Current balance / due breakdown (Middle) ---
  CardTextSlot.outstanding: CardVisualSlot(
    zone: CardZone.financialSecondary,
    area: CardVisualZone(x: .69, y: .06, width: .27, height: .24),
    maxLines: 2,
    minFontScale: .55,
  ),
  CardTextSlot.thisMonthDue: CardVisualSlot(
    zone: CardZone.financialPrimary,
    area: CardVisualZone(x: .30, y: .48, width: .34, height: .27),
    maxLines: 4,
    minFontScale: .52,
  ),
  CardTextSlot.nextMonthDue: CardVisualSlot(
    zone: CardZone.financialPrimary,
    area: CardVisualZone(x: .69, y: .48, width: .26, height: .27),
    maxLines: 4,
    minFontScale: .52,
  ),

  // --- Usage (Bottom) ---
  CardTextSlot.usedPercent: CardVisualSlot(
    zone: CardZone.usage,
    area: CardVisualZone(x: .08, y: .76, width: .84, height: .25),
    maxLines: 3,
    minFontScale: .70,
  ),

  // --- Cycle Info (Bottom Left, under chip) ---
  CardTextSlot.statementCycle: CardVisualSlot(
    zone: CardZone.footer,
    area: CardVisualZone(x: .08, y: .54, width: .25, height: .15),
    maxLines: 2,
    minFontScale: .62,
  ),
};

const CardVisualLayout _classicCardLayout = CardVisualLayout(
  visualId: 'classic',
  aspectRatio: 320 / 200,
  reservedZones: _standardReservedZones,
  slots: _standardSlots,
);

const CardVisualLayout _midnightCardLayout = CardVisualLayout(
  visualId: 'midnight',
  aspectRatio: 320 / 200,
  reservedZones: _standardReservedZones,
  slots: _standardSlots,
);

const CardVisualLayout _auroraCardLayout = CardVisualLayout(
  visualId: 'aurora',
  aspectRatio: 320 / 200,
  reservedZones: _standardReservedZones,
  slots: _standardSlots,
);

/// Standard compact layout.
const CardVisualLayout compactFinancialLayout =
    CardVisualLayout(
  visualId: 'compact_financial',
  aspectRatio: 1.586,
  reservedZones: <CardVisualZone>[
    CardVisualZone(x: 0.06, y: 0.22, width: 0.22, height: 0.34),
    CardVisualZone(x: 0.72, y: 0.16, width: 0.22, height: 0.30),
  ],
  slots: <CardTextSlot, CardVisualSlot>{
    CardTextSlot.cardName: CardVisualSlot(
      zone: CardZone.identity,
      area: CardVisualZone(x: 0.08, y: 0.06, width: 0.42, height: 0.12),
      maxLines: 1,
      maxFontScale: 1.0,
    ),
    CardTextSlot.issuer: CardVisualSlot(
      zone: CardZone.identity,
      area: CardVisualZone(x: 0.08, y: 0.17, width: 0.40, height: 0.10),
      maxLines: 1,
      maxFontScale: 0.78,
    ),
    CardTextSlot.cardholder: CardVisualSlot(
      zone: CardZone.identity,
      area: CardVisualZone(x: 0.08, y: 0.78, width: 0.36, height: 0.10),
      maxLines: 1,
      maxFontScale: 0.82,
    ),
    CardTextSlot.maskedNumber: CardVisualSlot(
      zone: CardZone.identity,
      area: CardVisualZone(x: 0.30, y: 0.30, width: 0.42, height: 0.10),
      maxLines: 1,
      maxFontScale: 0.78,
    ),
    CardTextSlot.outstanding: CardVisualSlot(
      zone: CardZone.financialSecondary,
      area: CardVisualZone(x: 0.69, y: 0.06, width: 0.27, height: 0.24),
      maxLines: 2,
      minFontScale: 0.55,
    ),
    CardTextSlot.monthlyInstallment: CardVisualSlot(
      zone: CardZone.financialPrimary,
      area: CardVisualZone(x: 0.36, y: 0.42, width: 0.27, height: 0.22),
      maxLines: 2,
      maxFontScale: 1.0,
    ),
    CardTextSlot.totalInstallment: CardVisualSlot(
      zone: CardZone.financialPrimary,
      area: CardVisualZone(x: 0.64, y: 0.42, width: 0.27, height: 0.22),
      maxLines: 2,
      maxFontScale: 1.0,
    ),
    CardTextSlot.usedPercent: CardVisualSlot(
      zone: CardZone.usage,
      area: CardVisualZone(x: 0.36, y: 0.76, width: 0.55, height: 0.11),
      maxLines: 1,
      minFontScale: 0.68,
    ),
    CardTextSlot.usedAmount: CardVisualSlot(
      zone: CardZone.usage,
      area: CardVisualZone(x: 0.36, y: 0.82, width: 0.55, height: 0.09),
      maxLines: 1,
      minFontScale: 0.68,
    ),
    CardTextSlot.status: CardVisualSlot(
      zone: CardZone.status,
      area: CardVisualZone(x: 0.52, y: 0.06, width: 0.16, height: 0.12),
      maxLines: 1,
      minFontScale: 0.68,
    ),
    CardTextSlot.overdue: CardVisualSlot(
      zone: CardZone.status,
      area: CardVisualZone(x: 0.36, y: 0.61, width: 0.27, height: 0.09),
      maxLines: 1,
      minFontScale: 0.68,
    ),
  },
);

const Map<WafferlyCardKind, Set<CardTextSlot>>
    defaultCardFieldPolicy = <WafferlyCardKind, Set<CardTextSlot>>{
  WafferlyCardKind.credit: <CardTextSlot>{
    CardTextSlot.cardName,
    CardTextSlot.issuer,
    CardTextSlot.maskedNumber,
    CardTextSlot.network,
    CardTextSlot.status,
    CardTextSlot.available,
    CardTextSlot.creditLimit,
    CardTextSlot.usedAmount,
    CardTextSlot.usedPercent,
    CardTextSlot.monthlyInstallment,
    CardTextSlot.totalInstallment,
    CardTextSlot.outstanding,
    CardTextSlot.thisMonthDue,
    CardTextSlot.nextMonthDue,
    CardTextSlot.minimumPayment,
    CardTextSlot.overdue,
    CardTextSlot.statementCycle,
  },
  WafferlyCardKind.debit: <CardTextSlot>{
    CardTextSlot.cardName,
    CardTextSlot.issuer,
    CardTextSlot.maskedNumber,
    CardTextSlot.network,
    CardTextSlot.status,
    CardTextSlot.balance,
    CardTextSlot.currency,
  },
  WafferlyCardKind.prepaid: <CardTextSlot>{
    CardTextSlot.cardName,
    CardTextSlot.issuer,
    CardTextSlot.maskedNumber,
    CardTextSlot.network,
    CardTextSlot.status,
    CardTextSlot.balance,
    CardTextSlot.available,
    CardTextSlot.currency,
  },
  WafferlyCardKind.virtual: <CardTextSlot>{
    CardTextSlot.cardName,
    CardTextSlot.issuer,
    CardTextSlot.maskedNumber,
    CardTextSlot.network,
    CardTextSlot.status,
    CardTextSlot.balance,
    CardTextSlot.available,
    CardTextSlot.creditLimit,
    CardTextSlot.currency,
  },
  WafferlyCardKind.charge: <CardTextSlot>{
    CardTextSlot.cardName,
    CardTextSlot.issuer,
    CardTextSlot.maskedNumber,
    CardTextSlot.network,
    CardTextSlot.status,
    CardTextSlot.available,
    CardTextSlot.usedAmount,
    CardTextSlot.usedPercent,
    CardTextSlot.minimumPayment,
    CardTextSlot.overdue,
  },
  WafferlyCardKind.other: <CardTextSlot>{
    CardTextSlot.cardName,
    CardTextSlot.issuer,
    CardTextSlot.maskedNumber,
    CardTextSlot.network,
    CardTextSlot.status,
    CardTextSlot.balance,
    CardTextSlot.available,
    CardTextSlot.currency,
  },
};

Set<CardTextSlot> fieldsForCardKind(WafferlyCardKind kind) =>
    Set<CardTextSlot>.unmodifiable(
      defaultCardFieldPolicy[kind] ?? const <CardTextSlot>{},
    );
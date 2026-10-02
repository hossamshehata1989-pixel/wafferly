WAFFERLY - Dynamic SVG Card Layout Patch

Replace these two files in your project:

lib/screens/accounts/liabilities/credit_card_account_details_screen.dart
lib/widgets/shared/wafferly_card_visual_layout.dart

What changed:
- Credit Card Details screen now resolves the layout from profile.cardVisual.
- The selected SVG remains the actual card background.
- Overlay fields use semantic CardTextSlot positions instead of hard-coded
  Positioned percentages inside the screen.
- Built-in layouts are provided for classic, midnight, and aurora.
- Unknown/new visuals fall back to classic until a visual-specific layout is
  registered in wafferly_card_visual_layout.dart.
- The same layout system is intentionally generic and can be reused by
  debit/prepaid/virtual/charge/other financial cards.

After replacement:
flutter clean
flutter pub get
flutter run

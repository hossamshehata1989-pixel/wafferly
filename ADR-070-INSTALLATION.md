# ADR-070 Clean Integration Patch v2

Apply from `D:\wafferly`.

## Create these exact files
- `lib/models/financing/financing_conversion_event.dart`
- `lib/models/financing/financing_conversion_event.g.dart`
- `lib/financing/domain/credit_card_financing_conversion.dart`
- `test/financing/credit_card_financing_conversion_test.dart`
- `test/architecture/financing_conversion_writer_boundary_test.dart`

## Modify `lib/main.dart` only
1. Add:
   `import 'models/financing/financing_conversion_event.dart';`
2. Register adapter typeId 114 after typeId 113:
```dart
if (!Hive.isAdapterRegistered(114)) {
  Hive.registerAdapter(FinancingConversionEventAdapter());
}
```
3. Open the box with the other financing boxes:
```dart
await Hive.openBox<FinancingConversionEvent>(
  'financing_conversion_events',
);
```

Do NOT replace `lib/main.dart` with the main.dart included in the previous ZIP.

## Then run
```powershell
flutter pub get
flutter test test/financing/credit_card_financing_conversion_test.dart
flutter test test/architecture/financing_conversion_writer_boundary_test.dart
```

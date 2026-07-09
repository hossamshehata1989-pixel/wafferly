import 'resolution.dart';

extension ResolutionLabelExtension on Resolution {
  String get label {
    switch (this) {
      case Resolution.execute:
        return 'Execute';

      case Resolution.tempDebt:
        return 'Temporary Debt';

      case Resolution.addBalance:
        return 'Add Balance';

      case Resolution.cancel:
        return 'Cancel';
    }
  }
}

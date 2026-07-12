// lib/features/transactions/models/entry_mode_extension.dart

import 'entry_mode.dart';
import 'entry_mode_config.dart';

extension EntryModeExtension on EntryMode {
  EntryModeConfig get config => EntryModeConfig.of(this);
}

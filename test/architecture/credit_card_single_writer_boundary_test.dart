import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Credit Card feature does not directly write financial truth', () {
    final root = Directory.current;
    final featureRoot = Directory(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}credit_card',
    );

    if (!featureRoot.existsSync()) {
      fail('Credit Card feature directory is missing.');
    }

    final forbidden = <RegExp>[
      RegExp(r'Hive\.box<\s*Transaction\s*>'),
      RegExp(r'Hive\.box<\s*Account\s*>'),
      RegExp(r'\.put\s*\('),
      RegExp(r'\.delete\s*\('),
      RegExp(r'\.deleteAll\s*\('),
      RegExp(r'TransactionApplicationService'),
    ];

    final violations = <String>[];

    for (final entity in featureRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final content = entity.readAsStringSync();
      for (final pattern in forbidden) {
        if (pattern.hasMatch(content)) {
          violations.add('${entity.path}: ${pattern.pattern}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Credit Card financial truth must be mutated only through the '
          'Financial Engine. Violations: ${violations.join('; ')}',
    );
  });
}

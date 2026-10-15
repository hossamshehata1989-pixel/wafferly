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
    _collectViolations(featureRoot, forbidden, violations);

    expect(
      violations,
      isEmpty,
      reason:
          'Credit Card financial truth must be mutated only through the '
          'Financial Engine. Violations: ${violations.join('; ')}',
    );
  });

  test('Credit Cards screen does not access Hive directly', () {
    final root = Directory.current;
    final screenFile = File(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}screens'
      '${Platform.pathSeparator}manage${Platform.pathSeparator}credit_cards_screen.dart',
    );
    if (!screenFile.existsSync()) {
      fail('Credit Cards screen is missing: ${screenFile.path}');
    }

    final content = screenFile.readAsStringSync();
    final forbidden = <RegExp>[
      RegExp(r"package:hive(_flutter)?/hive(_flutter)?\.dart"),
      RegExp(r'\bHive\s*\.\s*(box|isBoxOpen)\s*(<[^>]+>)?\s*\('),
      RegExp(r'\.(put|delete|deleteAll)\s*\('),
    ];
    final violations = <String>[];
    for (final pattern in forbidden) {
      if (pattern.hasMatch(content)) {
        violations.add('${screenFile.path}: ${pattern.pattern}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'The Credit Cards screen must use an application projection '
          'service for persistence access. Violations: ${violations.join('; ')}',
    );
  });
}

void _collectViolations(
  Directory directory,
  List<RegExp> forbidden,
  List<String> violations,
) {
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final content = entity.readAsStringSync();
    for (final pattern in forbidden) {
      if (pattern.hasMatch(content)) {
        violations.add('${entity.path}: ${pattern.pattern}');
      }
    }
  }
}

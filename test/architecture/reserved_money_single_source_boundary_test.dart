import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy ReservedMoney store has no production references', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final violations = <String>[];

    final files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final forbidden = <RegExp>[
      RegExp(
        r'''(?:import|export|part)\s+['"](?:[^'"]*/)?reserved_money_service\.dart['"]''',
      ),
      RegExp(r'\bReservedMoneyService\b'),
      RegExp(
        r'''Hive\.(?:openBox|box)<\s*ReservedMoney\s*>\(\s*['"]reserved_money['"]\s*\)''',
      ),
      RegExp(
        r'''Hive\.(?:openBox|box)\s*\(\s*['"]reserved_money['"]\s*\)''',
      ),
      RegExp(r'''['"]reserved_money['"]'''),
    ];

    for (final file in files) {
      final relative = file.path
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^\./'), '');

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;

        for (final pattern in forbidden) {
          if (pattern.hasMatch(line)) {
            violations.add('$relative:L${i + 1}: ${line.trim()}');
            break;
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Reserved Money must have one production read/write truth: active Planning Allocations.\n'
          '${violations.join('\n')}',
    );
  });

  test('legacy ReservedMoney implementation files remain retired', () {
    const paths = <String>[
      'lib/services/reserved_money_service.dart',
      'lib/services/virtual_saving_service.dart',
      'lib/models/reserved_money.dart',
      'lib/models/reserved_money.g.dart',
      'lib/models/enums/reserved_money_type.dart',
      'lib/models/enums/reserved_money_type.g.dart',
    ];

    for (final path in paths) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason: 'Legacy Reserved Money file must remain retired: $path',
      );
    }
  });
}

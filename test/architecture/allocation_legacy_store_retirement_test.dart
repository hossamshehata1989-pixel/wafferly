import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy AllocationService/store has no production references', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final violations = <String>[];

    final files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final forbidden = <RegExp>[
      // Exact legacy AllocationService file import/export/part.
      RegExp(
        r"""(?:import|export|part)\s+['"](?:[^'"]*/)?allocation_service\.dart['"]""",
      ),

      // Legacy service symbol.
      RegExp(r'\bAllocationService\b'),

      // Legacy Hive allocation store.
      RegExp(
        r"""Hive\.(?:openBox|box)<\s*Allocation\s*>\(\s*['"]allocations['"]\s*\)""",
      ),
    ];

    for (final file in files) {
      final relative = file.path
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^\./'), '');

      final lines = file.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        if (line.trimLeft().startsWith('//')) {
          continue;
        }

        for (final pattern in forbidden) {
          if (pattern.hasMatch(line)) {
            violations.add(
              '$relative:L${i + 1}: ${line.trim()}',
            );
            break;
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'The retired legacy Allocation store must not regain production references.\n'
          '${violations.join('\n')}',
    );
  });

  test('known orphan legacy allocation services/adapters are absent', () {
    const paths = <String>[
      'lib/services/allocation_service.dart',
      'lib/services/allocation_projection_service.dart',
      'lib/services/goal_projection_service.dart',
      'lib/infrastructure/adapters/allocation/create_allocation_adapter.dart',
    ];

    for (final path in paths) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason: 'Legacy file must remain retired: $path',
      );
    }
  });
}
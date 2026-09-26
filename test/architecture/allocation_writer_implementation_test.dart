import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AllocationAdapter does not write AllocationRepository directly', () {
    final file = File('lib/infrastructure/adapters/allocation_adapter.dart');
    expect(file.existsSync(), isTrue);

    final source = file.readAsStringSync();
    final executableLines = source
        .split('\n')
        .map((line) {
          final index = line.indexOf('//');
          return index == -1 ? line : line.substring(0, index);
        })
        .toList();

    expect(
      executableLines.any(
        (line) =>
            line.contains('allocationRepository.') &&
            (line.contains('.create(') ||
                line.contains('.update(') ||
                line.contains('.delete(')),
      ),
      isFalse,
      reason:
          'AllocationAdapter may read AllocationRepository, but all writes must go through PlanningEngine.',
    );
  });
}

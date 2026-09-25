// Money Boundary Guard — closed M1 baseline.
//
// Financial domain/planning amounts must be Money. double is permitted only at
// explicitly proven compatibility/persistence boundaries outside this scan.
//
// The previous 12-file double-amount debt was migrated in M1. This ratchet is
// now intentionally empty: any new double amount/debit/credit/balance in the scanned
// domain/planning roots fails immediately.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Explicitly proven persistence boundary. The Hive representation remains
/// double because it is the legacy storage format; conversion to/from Money
/// happens at the adapter boundary.
const Map<String, String> _provenBoundary = {
  'lib/core/planning/infrastructure/persistence/hive_allocation_record.dart':
      'Hive persistence representation; Money conversion is performed at the persistence boundary.',
};

final RegExp _doubleFinancialAmountPattern = RegExp(
  r'\b(?:final\s+|required\s+)?double\s+(?:amount|debit|credit|balance)\b|\b(?:amount|debit|credit|balance)\s*:\s*double\b|\bdouble\s+get\s+(?:amount|balance)\b|\bdouble\s+Function\s*\(String\s+accountId\)',
);

void main() {
  test(
    'financial domain does not introduce double monetary fields',
    () {
      const scannedRoots = ['lib/financial_engine', 'lib/core/planning'];
      final violations = <String>{};

      for (final root in scannedRoots) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;

        final dartFiles = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final relativePath = file.path
              .replaceAll('\\', '/')
              .replaceFirst(RegExp(r'^\./'), '');

          if (_provenBoundary.containsKey(relativePath)) continue;

          for (final rawLine in file.readAsLinesSync()) {
            final line = _withoutLineComment(rawLine);
            if (_doubleFinancialAmountPattern.hasMatch(line)) {
              violations.add(relativePath);
              break;
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Financial domain/planning contains unapproved double monetary '
          'types:\n${violations.map((path) => ' - $path').join('\n')}',
        );
      }
    },
  );
}

String _withoutLineComment(String line) {
  final commentIndex = line.indexOf('//');
  return commentIndex == -1 ? line : line.substring(0, commentIndex);
}
